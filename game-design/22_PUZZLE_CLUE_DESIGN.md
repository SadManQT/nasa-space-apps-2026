# 22 — Puzzle and Clue Design: every mission a story-driven investigation (`EX-M0101`–`EX-M0804`)

- **Date:** 4 November 2026 · **Board task:** `M1-38` · **Depends on:** `M1-27`, `M1-39`
- **Canon this document obeys (it never overrides them):**
  - Story, scenes, dialogue: [`full-game-story/STORY_FULL.md`](../full-game-story/STORY_FULL.md) / [`story-data.json`](../full-game-story/story-data.json). Every quoted line below carries its line ID and is copied word for word.
  - Numbers: [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) (`P-01`..`P-16`). No number here is new; where a section needs a number, it is the 08 value.
  - NASA practice: [`23_NASA_MISSION_PRACTICE.md`](23_NASA_MISSION_PRACTICE.md) (trade-study card `MP-01`, flight rules `FR-01`..`FR-06`, Go/No-Go `MP-03`, ODF checklists `MP-04`, 5×5 risk matrix and MER workflow `MP-07`, CAPCOM and link windows `MP-08`).
  - Data Cards: fixtures in [`game/resources/data/nasa/`](../game/resources/data/nasa/) as mapped in `puzzle_sources.json` and [`docs/SCIENCE_AND_DATA.md`](../docs/SCIENCE_AND_DATA.md) §B1–B2. Tags: `[M]` measured, `[C]` computed, `[E]` estimate, `[G]` gameplay, `[F]` fiction.
  - Locked decisions in [`PRODUCTION_HANDBOOK.md`](../PRODUCTION_HANDBOOK.md) §3: English only (the seed packet reads "ALO" and "N." in Latin letters, overriding the prose's "Bengali lettering" in `EX-CH01-S03`); plants never have eyes or faces; Moon science rules ([`ART_BIBLE.md`](../production/ART_BIBLE.md) §2); P-05's four phases are an abstract budget that adds no story hours.
- **Relationship to [`19_TRAINING_DECISIONS.md`](19_TRAINING_DECISIONS.md):** this document supersedes 19 for every mission. 19 was written with a non-canon cast (Ayla, Sofia, Liam, Noah), a non-canon crop ("Lal Shak"), non-canon puzzle contracts (for example a P-01 with heat/light/oxygen/water sliders) and fixture IDs that do not exist in `game/resources/data/nasa/`. Where 19 and this file disagree, this file and the canon above win. Each mission section here therefore also carries what 19 was meant to give implementers: the four-demand Outpost Status view, the Data Card, the outcomes and the debrief question (taken from the scene's canon `learning` block).

> **One sentence for a 10–12-year-old:** every mission is a small mystery: you find clues around the station, work out what they mean, and then make a careful decision with your crew the way real NASA teams do.

---

## 0. How to read a mission section

Each of the 32 sections has the same five parts, matching the task brief:

1. **Investigation:** 3–6 core clues (some missions list one or two extra supporting clues). Each row gives the clue, its kind, where it is, and which cadet holds it privately in Class mode (`M1-37`).
2. **Deduction:** what the player must connect, the "aha", and the *wrong-but-reasonable* idea a smart player tries first, with the game's non-punishing answer.
3. **Decision and escalation:** the decision made the NASA way, stakes rising across the three scenes, the set-piece payoff, and how success, partial success and failure feel different.
4. **Hints:** three tiers (H1 nudge, H2 direction, H3 worked example) and the Family / Cadet / Engineer differences.
5. **Playtime and feel:** the target minutes (canon pacing from `story-data.json`) and what the hands do and the ears hear.

**Clue kinds.** `DLG` an existing canon line (quoted with its ID; never reworded) · `LOG` a record that exists in canon (N.'s recordings, Expedition Zero papers, notebooks, manifests) · `INS` an instrument readout (a game-state value from 08 or a value from a NASA fixture) · `OBJ` an object placed in the room · `CARD` a Data Card fixture · `NEW` new world text written here (labels, log metadata, hint text). New text is never spoken dialogue: no new voice lines are proposed anywhere in this file.

**Class-mode holders.** **K** Kai (power and heat) · **A** Amara (atmosphere and measurement) · **M** Mei (horticulture) · **R** Rafi (safety and field) · **All** shared screen. Lines spoken by Ferreira, Rao, Noor or Kai's family are heard by everyone and are always **All**. A private clue is revealed on that cadet's role card (printed or pass-the-laptop); in Solo every card is reachable by switching cadet (keys 1–4) and in the Journal, so no clue is ever reachable only through a person ([`10_GAMEPLAY_SYSTEMS.md`](10_GAMEPLAY_SYSTEMS.md) §Role facts). Reading every card is never a forced success gate, and nothing here claims that ignoring one clue removes a star.

**Outcome tiers (all missions).** *Success* reaches the canon exit gate with the plan verified on its first commit. *Partial success* reaches the same gate with a known weaker margin, an advisory accepted, or after a preview or interlock caught a mistake; it never blocks the story and is shown only in the debrief and the chapter's [G] mastery stars (10_GAMEPLAY_SYSTEMS §Station Days, three-star criteria). *Failure* is always safe and informative: an interlock or paused preview stops the step, names the breached demand in text and icon, and offers the checkpoint without losing story progress. Hints and assisted input never change an ending (08, "Accessible input").

---

## 1. Design principles borrowed from proven games (principles only, no content)

| ID | Source | Principle we borrow | How it shows up here | Main missions |
|---|---|---|---|---|
| **T1** | *Outer Wilds* | **Knowledge is the only key.** Nothing is unlocked by picking up an item; understanding opens the next step. The ship log shows unexplored "rumour" links. | The Journal **Evidence Board**: every clue card files itself with its source object; dotted rumour threads connect it to open questions; a step unlocks only when the player commits a claim that fits *all* linked clues. | The N. thread CH01→CH07; P-04, P-09, P-10 |
| **T2** | *Return of the Obra Dinn* | **Deduction journal with fixed empty slots;** the game confirms only what evidence supports and leaves the rest blank; confirmation of a whole set discourages guessing. | Three columns, **Observed / Inferred / Unknown** (canon in `EX-CH02-S10`); the "clean empty space where a person might later belong" (`EX-CH02-S08`) stays blank until the signed page (`EX-CH05-S10`). Chronology and identity conclusions commit only as a complete set. | CH02, CH04-S11, CH05 |
| **T3** | *Frostpunk* | **Laws signed before the crisis; scarcity always visible; an announced countdown.** | Flight rules `FR-01`..`FR-06` are read and acknowledged before any dark night (charter card `EX-CH01-S01`); the Outpost Status bar and Mission Table forecast show every allocation before commit; the storm alarm is announced on a schedule the team drew itself. | P-02, P-11, P-13/P-14 |
| **T4** | *Subnautica* | **Survival trade-offs measured as a safe-return budget;** systems you built yourself; logs tie story to survival. | Rover and route cards draw the **return reserve line** (30 of 100 in P-07, 2 of 14 in P-15) as a "home" marker on the bar; base and rover ledgers are separate; the calibrated scanner is the discovery tool. | P-07, P-08, P-15 |
| **T5** | *Death Stranding* | **Route and load planning on a terrain map with slope readout; infrastructure placed earlier becomes the network that carries people's voices later; cargo needs handling care.** | Route cards show slope numbers with pattern overlays (never colour alone); beacons (CH04) and repeaters (CH07–CH08) are player-built and later carry the most important voice in the game; the vault travels in sleeve, cradle and mount. | P-07, P-08, P-15, P-16 |
| **T6** | *Portal* | **Teach one rule in a safe chamber, then combine rules under pressure; never test a rule before teaching it.** | Every new rule gets a no-cost rehearsal first: the shelter drill (`EX-CH01-S08`), the nonliving flower model (`EX-CH02-S02`), the rehearsal fault (`EX-CH06-S05`), the bench echo test (`EX-CH07-S11`). The real event combines them. | Every chapter |
| **T7** | *The Witness* | **A rule learned in one panel returns with one new constraint each time;** the "aha" is seeing the world differently. | **The Reference Ladder** (§2.2): "a reference before the interesting number" escalates from two-point calibration to an exact checksum across eight chapters. | P-01, P-05, P-07, P-10, P-14, P-16 |
| **T8** | *Firewatch* | **A relationship carried by a radio voice while the hands work;** the voice becomes a person when they arrive. | Ferreira on the Earth link (CH01–CH04) arrives in body (`EX-CH05-S01`); split-team local radio (CH04, CH08); Noor's first live voice waits for a link the player proved. | CH01–CH08 |
| **T9** | *Gone Home* | **Environmental storytelling with ordinary objects; recordings triggered by finding things.** | The four unnamed mugs → the fifth mug; Kai's hand light; Rafi's paper bee; Amara's visible correction label; Kai's compatibility note in the crate; the pressed petal. N.'s first recording plays when the player tags the bloom photograph (`EX-CH01-S12`). | Every chapter |
| **T10** | *Obra Dinn* / *Outer Wilds* | **A wrong theory is information, not punishment.** | Every "wrong-but-reasonable" idea runs in a paused preview that costs nothing and stays visible in the debrief (canon: "A mistaken plan is informative because it remains a preview", `EX-CH03-S03`). | Every mission |

---

## 2. Campaign-wide systems every mission section relies on

### 2.1 The investigation loop

1. **Find.** Walk and inspect real props; a clue files itself to the Evidence Board with its source object, scene and evidence tag. Story-required clues are automatic; nothing required is hidden (10_GAMEPLAY_SYSTEMS §Station Days).
2. **Sort.** Observed / Inferred / Unknown. A clue can move columns only with a new source.
3. **Deduce.** Link two or more clues to a claim. The board tests the claim against *every* linked clue and shows the one it contradicts (canon learning `EX-CH03-S02`: "A theory that fits one reading may fail the rest.").
4. **Decide the NASA way** ([23](23_NASA_MISSION_PRACTICE.md)): open the **trade-study card** (23 §1.3: plain question, active flight rules, options with power / consumables / risk / crew-time deltas, dissent note, one-sentence rationale, evidence chips); check **flight rules** (23 §2.2); run the **Go/No-Go poll** for multi-role operations or a **closed-loop read-back** for small calls (23 §3.3); follow the **ODF checklist** for hands-on steps (23 §4.3); place the hazard on the **5×5 risk card** (23 §7.2).
5. **Commit and live with it.** The Outpost Status bar ([`outpost_status.json`](../game/resources/campaign/outpost_status.json): Power `E`, Life support `A`/`W`, Shielding `S`/`Z`, Food `H`/`C`/`R`) shows the change. The debrief uses the scene's canon Predict → Observe → Explain and the five-panel blame-free review (23 §7.4).

### 2.2 The Reference Ladder (The Witness-style escalation across the campaign)

One rule, introduced by Rafi in `EX-CH01-S03-L04` ("And a reference before the interesting number."), returns eight times, each time with one new constraint:

| Rung | Mission | What is new | 08 numbers |
|---|---|---|---|
| 1 | `EX-M0101` P-01 | Two-point calibration: zero on dry, span on wet, recheck | dry 10 → 0, wet 110 → 100 |
| 2 | `EX-M0301` P-05 | An *independent* instrument beats the panel's diagnosis | MAIN 100/100, GARDEN 82/74, RETURN 100/100 |
| 3 | `EX-M0302` P-05 | One reading is not verification: five consecutive checks | five 2-second readings 100/100/100 |
| 4 | `EX-M0402` P-07 | Reference *plus threshold*, and keep the negative control | dry 2, threshold 12, samples 2/18/19 |
| 5 | `EX-M0503` P-10 | Compare *across frames*: what persists is the instrument | 8 transients, 2 fixed artifacts, 6 to verify |
| 6 | `EX-M0703` P-14 | Two readings *separated in time* | 0.4 then 0.3 clear; 1.2 does not; threshold 1 |
| 7 | `EX-M0802` P-15 | A light is not a link: test *both neighbours* | repeater chain 1→2→3 |
| 8 | `EX-M0803` P-16 | Strong is not correct: *exact* content | checksum ALO42 |

### 2.3 Hints in three tiers

- **H1 nudge** points at the clue ("look here"). **H2 direction** names the relationship ("these two things share one tank"). **H3 worked example** walks through the reasoning or the 08 solution text; it never pre-fills a control, and the player still sets every value and presses Commit (19 §0 rule 1 and `B06` stay in force).
- Puzzle steps use the **08 H1/H2/H3 text verbatim** (and P-02's Golden G1/G2 after a first Bloom). Non-puzzle decisions use the `NEW` hint text given in each section; it is Journal and card text, never a spoken line.
- Hints are offered from the trade-study card and the Journal. Using one never changes an ending, a star or a reward.

### 2.4 Mode differences that apply everywhere

| Mode | What changes | What never changes |
|---|---|---|
| **Family** (6+ with an adult) | No action timers; every drag or hold is Select source → Select target → Confirm; H1 is offered after a rejected preview or a long pause; P-02 and P-13 Guided plans available. | Story, solutions, endings, rewards |
| **Cadet** (default) | Optional pressure only where 08 allows it (P-02 PUMP 15 s / STACK 30 s with an assisted alternative; P-12 optional 90 s with pause); hints on request. | Same |
| **Engineer** | Real-unit subtitles from the fixtures with their tags (`[M]`/`[C]`/`[E]`/`[G]`), the formula behind each 08 number, the flight-rule thresholds as numbers; H3 shows the arithmetic. Never presents game exposure `Z` as mSv. | Same |
| **Class** (2–4 groups, one operator) | Private role cards; each group signs its own Go/No-Go before Commit (23 §3.3). | Same |
| **Solo** | All role cards through cadet switching and the Journal; the poll is summarised in one confirm. | Same |

### 2.5 Feel vocabulary for outcomes

- **Light.** Success settles room light to warm white and the Outpost Status icons to their calm state. Partial leaves one amber advisory chip lit on the bar until the debrief explains it. Failure freezes the paused preview on the breached demand with red, an icon and a plain sentence; room lighting never strobes.
- **Sound.** Success: `SFX_UI_SHIFT_COMMIT` and the scene's music cue resolving. Partial: the cue holds instead of resolving. Failure: `SFX_UI_SOFT_ERROR` ("never a humiliating buzzer"). Outside the hull there is no airborne sound: suit, contact, cabin and rover-chassis sounds only.
- **Plant posture (never a face).** Alo's state reads through stem angle, leaf curl, lean toward the lamp, bud and flower opening, and in CH03 the yellowing of a plant finishing its life. After Alo's natural end on 21 May 2046, the same vocabulary moves to Tara's record, the descendant rack and, from 15 December, the cotton seedling. The pressed petal is an archive object and never moves.

### 2.6 Playtime budget (canon pacing)

Targets are the mission minutes in `story-data.json` (720 target minutes, range 600–840). Reading, caption hold and planning pause the clock and spend no hidden resources. No mission contains idle waiting: dated time cards carry long intervals.

| Chapter | Missions (target minutes) | Total |
|---|---|---|
| CH01 Night One | M0101 18 · M0102 18 · M0103 18 · M0104 21 | 75 |
| CH02 Be the Bee | M0201 18 · M0202 18 · M0203 18 · M0204 21 | 75 |
| CH03 Moonquake | M0301 20 · M0302 21 · M0303 21 · M0304 23 | 85 |
| CH04 Into the Cold Trap | M0401 22 · M0402 22 · M0403 22 · M0404 24 | 90 |
| CH05 Shooting Stars | M0501 20 · M0502 20 · M0503 25 · M0504 20 | 85 |
| CH06 The Red Ring | M0601 20 · M0602 25 · M0603 20 · M0604 20 | 85 |
| CH07 The Great Storm | M0701 25 · M0702 25 · M0703 30 · M0704 25 | 105 |
| CH08 The Lighthouse | M0801 30 · M0802 30 · M0803 30 · M0804 30 | 120 |

Twenty-seven of the 32 missions sit in the 15–25 minute band. The five longer ones (M0703 and all four CH08 missions, 30 minutes each) are the canon climaxes; their extra minutes are split-team play and the finale, not padding.

### 2.7 Where each 08 puzzle lives in the final missions

| Puzzle | Missions and scenes |
|---|---|
| P-01 Commission and Plant | M0101 S03 (calibration, packet scan) → M0102 S04 (one seed each, water, labels, seals) |
| P-02 Seven Shifts, One Night | M0102 S06 (schedule preview) → M0103 S07–S09 (shifts 1–4) → M0104 S10–S12 (shifts 5–7, ending) |
| P-03 Alo Meets Tara | M0201 (protocol and route) → M0202 S04–S05 (three reciprocal runs) |
| P-04 Recorder Reconstruction | M0203 S07–S09 (metadata) → M0204 S10 (playback, send to Ferreira) |
| P-05 Find the Falling Pressure | M0301 (investigation) → M0302 S04–S05 (clamp and five checks) |
| P-06 A Harvest With a Future | M0302 S06 + M0303 S08 (map) → M0303 S09 (maturity, dry-down) → M0304 S10–S11 (42 = 12 + 30) |
| P-07 Survey and Return | M0401 S03 (route) → M0402 S04–S05 (beacons, ice scan) |
| P-08 Recover Without Ruining | M0402 S06 → M0403 S07–S09 → M0404 S10 |
| P-09 Reconstruct the Departure | M0501 S03 |
| P-10 Flashes and a Signature | M0503 S07–S08 → M0504 S10–S11 |
| P-11 Protect the Small Light | M0601 S03 → M0602 S04, S06 |
| P-12 Observe, Isolate, Restore | M0602 S05 (rehearsal) → M0603 S07 (ingress, ring) → M0604 S10–S11 (F2, egress) |
| P-13 One Integrated Storm Plan | M0701 → M0702 S04–S05 |
| P-14 Three Waves and a Broken Link | M0702 S06 → M0703 S07–S09 |
| P-15 Two Teams, One Road | M0704 S12 (teams) → M0801 → M0802 |
| P-16 The Link and the Living Garden | M0803 → M0804 |

---

## 3. Chapter 1 — *Night One* (`EX-M0101`–`EX-M0104`)

Chapter question: how can one crew keep people, a station and a living experiment safe through a 36-hour scenario night? Mastery: P-02 stars; Golden Bloom needs `H ≥ 5` (08).

### 3.1 `EX-M0101` — Give the Station a Crew

`EX-CH01-S01`..`S03` · Mission table, Safe Room doorway, dry-storage drawer and calibration bench · **P-01** steps 1–4 (dry zero, wet span, recheck, packet scan) · **18 min** · Data Cards: `vsat_relocatable_array` (why daylight overflows), `change4_cotton` (SRC-COTTON2019), `osdr_brassica_rapa_iss` · Outpost Status: Power (full jar, overflow arrow) and Life support (air gauge) are live; Shielding and Food show their commissioning baseline.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | The battery display's gold band is at the top while the mast panel still shows production; an overflow arrow points off the jar. | INS | Mission table (S01) | K |
| 2 | `EX-CH01-S01-L02` Amara: "Only if we notice what spills." | DLG | S01 | A |
| 3 | Four mugs with no names on the table. | OBJ | Mission table (S01) | All |
| 4 | Four name tokens on the Safe Room board, and the printed retreat sequence; `EX-CH01-S02-L01` Rafi: "These are names. We do not spend them." | OBJ + DLG | Safe Room doorway (S02) | R |
| 5 | A disconnected practice panel whose three readouts are tagged `LOCAL SENSOR`, `STORED GUIDANCE`, `LIVE LINK` (`NEW` labels). | INS | S02 | A |
| 6 | The sealed dry packet: two seeds, "ALO" and "N." in Latin letters, storage record. | LOG | Dry-storage drawer (S03) | M |
| 7 | The moisture probe reads 10 in the dry reference cup and 110 in the wet one (08: offset +10). | INS | Calibration bench (S03) | A |
| 8 | Historical card: cotton germinated in China's sealed Chang'e-4 experiment in 2019 (`change4_cotton` `[M]`). | CARD | S03 | M |

**2 · Deduction.** Connect clue 1 with clue 2: a full store cannot take more, so spare sunlight is lost unless it goes to a useful store (air tank) or load (bay lamp). In S03, connect clue 7 with Rafi's `EX-CH01-S03-L04` line: the probe is confidently wrong by the same amount on both cups. **Aha:** *"The dry cup reads 10, so every number this probe shows is 10 too high until we set its zero."* **Wrong-but-reasonable:** Kai's `EX-CH01-S01-L01` instinct, "A full battery sounds like a good problem.", leaves the energy where it is; the comparison preview shows the spill counter rising while the baseline stays unharmed. At the bench, a player trusts the first reading and reaches for the cassette; the seal step stays locked with `UNCALIBRATED — Check reference first` (`FR-06`), and nothing is lost.

**3 · Decision and escalation (the NASA way).** Trade-study card "Where should spare commissioning energy go?" with two valid options (Store air / Light the planting bay) and a third, non-committable column "Spill" for comparison; both valid options converge on the 25 April baseline (canon). The charter card introduces `FR-01` (crew first) and local stop authority (`EX-CH01-S02-L04`); the roll call is a four-name closed-loop read-back. The calibration is the first ODF checklist (Zero on dry → ✓ dry reads 0; Span on wet → ✓ wet reads 100; Recheck). Risk card: "Uncalibrated reading used for planting", likelihood 3 × consequence 3, MODERATE `[G]`. **Escalation:** S01 has no wrong answer, only waste → S02 the tokens are people, and the practice fault must be solved without the live link → S03 the first irreplaceable object: two old seeds that cannot be retried. **Set piece:** the inventory lamp blinks, the drawer slides, the music thins to one held note, and the packet fills the frame as Mei reads `EX-CH01-S03-L01` ("Alo means light. Someone named the packet before us."). **Outcomes:** *success*: route committed, roll call four of four, probe rechecks dry 0 / wet 100, packet copied without damage, both chamber diagrams compared. *Partial*: the calibration completes after the seal interlock fired once; the debrief keeps "reference added after a blocked step". *Failure*: opening the original packet or sealing uncalibrated is interlocked; the step resets with the packet untouched.

**4 · Hints.** Energy route (`NEW`): H1 "Follow the arrow after the battery is full." · H2 "A full store cannot take more; a tank or a lamp can still use it." · H3 "Route the spare to the air tank or to the bay lamp, then compare both with spilling it." Calibration (08 P-01): H1 "Check the instrument before trusting it." · H2 "Use the two reference cups." · H3 "Dry must read 0, wet 100, then fill both to 50." **Modes:** Family sets zero and span with two large select-confirm controls; Engineer shows "offset +10 `[G]`" and the array formula 8 drops × 10 kWh / 7.2 h = 11.1 kW `[E]`.

**5 · Playtime and feel.** 6 + 6 + 6 minutes. *Hands:* trace the flow line on the table with a finger, drag one energy token, flip four name tokens, turn the packet without opening it, twist the probe's zero and span knobs. *Ears:* `SFX_FAN_NORMAL` bed, `CUE-01` "Home Not Yet", the drawer, a probe tick; no exterior sound from the mast, only its panel.

### 3.2 `EX-M0102` — Two Plants, One Night Plan

`EX-CH01-S04`..`S06` · Garden glove ports and indoor reference bay, corridor and care station, mission table and horizon display · **P-01** steps 5–8 (one seed each, water 40–60, distinct labels, seals) and the **P-02** schedule preview · **18 min** · Data Cards: `osdr_brassica_rapa_iss` (one plant per cassette; Veggie lamp 200–300 µmol m⁻² s⁻¹), `fast_plants_lifecycle` (flowers in about 14 days), `lro_mazarico_2011_illumination` (longest darkness about 1.5 days → the 36 h scenario), `jpl_horizons_ch1_sky` · Outpost Status: Food (Alo `H`, crop `C`) appears for the first time; the night forecast previews all four demands without committing.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Calibrated probe in both cassettes; target band 40–60, nominal 50 (08). | INS | Glove ports (S04) | M |
| 2 | Two cassette labels written blank in S03, now `EXTERNAL TEST` (Alo) and `INDOOR REFERENCE` (Tara) (08); `EX-CH01-S04-L02` Amara: "A reference is a plant we care for, not one we ignore." | OBJ + DLG | S04 | A |
| 3 | Transfer-lid latch indicator, word plus icon; `EX-CH01-S04-L04` Rafi: "Transfer sealed. Two names, two records." | INS | S04 | R |
| 4 | The hand light hung handle-out beside the locker; `EX-CH01-S05-L03` Rafi: "Then it gets a backup. Here." | OBJ | Corridor (S05) | K |
| 5 | The dated care notebook; `EX-CH01-S05-L04` Amara: "Fourteen dated care entries. A bud is a useful result." | LOG | Care station (S05) | A |
| 6 | Three separate tracks on the horizon display: Sun, Earth link, station systems; a source tab separates the published illumination map from the authored schedule. | INS + CARD | Mission table (S06) | A |
| 7 | `EX-CH01-S06-L03` Mei: "Put the garden on it. The shelter borrows from us." and `EX-CH01-S06-L04` Rafi: "Put returning the water on it too." | DLG | S06 | M, R |

**2 · Deduction.** Connect clue 6 with clue 7: a dark array does not mean Earth is gone, an Earth outage does not switch off the air maker, and the shelter wall is filled from the garden's own reservoir (garden water = 6 − `W`, 08). **Aha:** *"Shielding the crew and watering the garden draw on the same tank, so borrowing must come with a return time."* **Wrong-but-reasonable:** "Keep the borrowed water in the wall for the rest of the night; people come first." It is the first canon option in S06; the paused forecast shows continued shielding beside the garden thirst it causes, the player compares it with "return after the required exposure resolves", and nothing is spent. At the cassette, a careful player overfills "to be safe"; 08's drain prompt removes the excess and the seed is never harmed.

**3 · Decision and escalation (the NASA way).** P-01 completes on its ODF card (packet scan → one seed each → water to 50 → distinct labels → seals; duplicate seed or label is blocked with the occupied cassette named, `FR-06`). S06 is a trade study between two complete night plans with no resources committed; the risk card places "Shelter water kept too long → garden thirst" at 5 × 3, HIGH (23 §7.2, "P-02 Thirst W>=4"). **Escalation:** S04 delicate hands and one-of-a-kind seeds → S05 the rhythm of care and the first sign of Kai's fear → S06 the coming night drawn on the table, where a mistake is found "while it is still a drawing". **Set piece:** S05's dated montage ends with the first photograph laid beside the latest one, and S06 ends with the low Sun still visible on the horizon strip ("Preparation has time to be an action"). Alo's posture across the montage: a straight seedling, then a first true leaf, then a bud. **Outcomes:** *success*: 1 + 1 planted inside 40–60 with distinct labels and closed seals, fourteen care entries, schedule corrected with the water's return on it. *Partial*: planting needed a drain or a label correction first. *Failure*: none destructive; 08 resets only the unsettled cassette.

**4 · Hints.** Planting uses the 08 P-01 hints above. Schedule (`NEW`): H1 "Which room does the shelter water come from?" · H2 "Put the water's return on the same timeline as the storm." · H3 "Compare two whole nights: wall full until dawn, or water returned after the exposure resolves. Read the garden line in both." **Modes:** Family places seeds by select-confirm with no precision; Engineer shows `jpl_horizons_ch1_sky` (Earth set at the pole on 15 April 2046 and stays 3.4°–1.4° below the horizon through the night) beside the "training scenario" label on the shift-4 cutoff (SCIENCE_AND_DATA §B3-5).

**5 · Playtime and feel.** 6 + 6 + 6 minutes. *Hands:* glove ports, tweezers to cassette, a fill valve turned until the probe reads 50, pressing nameplates, hanging the lamp on its hook, laying three transparent track strips on the table. *Ears:* `SFX_GLOVE_PORT`, `SFX_GREENHOUSE_FAN`, `CUE-02` "Small Work", pencil on paper, soft date-card transitions.

### 3.3 `EX-M0103` — Prepare While It Is Light

`EX-CH01-S07`..`S09` · Air console and mast panel, Safe Room practice interface, mission table and Earth-facing viewport · **P-02** shifts 1–4 · **18 min** · Data Cards: `bvad_2022_metabolic` (1 air unit = 1.07 kg O₂ for four crew per 7.2 h `[C]`), `vsat_relocatable_array`, `donki_2017_09` (labelled 2017 replay), `clowdsley_2021_shielding` (wall 6 = 20 g/cm² `[C]`), `jpl_horizons_ch1_sky` · Outpost Status: all four demands live from the 08 start state `E14/20, A6/10, H6/10, W0/6, K0/2, C8/10, R12, Z0`.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Role card, shift 1: "Make air during daylight before excess jar income spills." (10_GAMEPLAY_SYSTEMS role facts) | LOG | Air console (S07) | A |
| 2 | Role card, shift 1: "Five dark shifts, about 36 h; heat spends the finite night reserve." | LOG | Mast panel (S07) | K |
| 3 | Day income +8 in shifts 1–2, cap 20; breathing −1 per shift (08). | INS | Mission Table | All |
| 4 | Role card, shift 2: "Labelled 2017 replay feed: sunspot 2673 fired a large flare; more activity is possible." (`donki_2017_09`: X9.3 flare, 6 Sep 2017 11:53 UT `[M]`). Debrief line: "The real X9.3 and X8.2 flares (10 Sep 15:35 UT) were 4 days 3.7 h apart; the replay squeezes four days into one." (DONKI <https://ccmc.gsfc.nasa.gov/DONKI-API/get/FLR?startDate=2017-09-04&endDate=2017-09-12>) | LOG + CARD | Safe Room feed (S08) | R |
| 5 | The drill: water traced from garden reservoir to wall and back; supply bundles previewed as shielding; `EX-CH01-S08-L03` Amara: "Practice complete. Baseline unchanged." | INS + DLG | Safe Room interface (S08) | A |
| 6 | Role card, shift 3: "This scenario’s direct plant threats are cold near or below freezing and thirst; shielding borrows the garden reservoir." (thirst at `W ≥ 4`, 08; COLD is not called frost: heavy *Brassica* frost is below −2 °C, Canola Council of Canada <https://www.canolacouncil.org/canola-watch/2017/09/07/fall-frost-swathing-and-straight-combining-considerations>) | LOG | Garden panel (S09) | M |
| 7 | `EX-CH01-S09-L04` Ferreira (Earth link before cutoff): "Local rules remain active. Read back the next safe action." | DLG | Earth console (S09) | All |

**2 · Deduction.** This is the combined-evidence decision (10_GAMEPLAY_SYSTEMS GAME-05): Rafi's storm card plus Mei's thirst card decide *when to fill the wall and when to return the water*; Kai's budget and Amara's air decide what the team can afford meanwhile. **Aha 1:** *"Sunlight will overflow the jar anyway, so the air we make now is almost free."* **Aha 2:** *"Fill the wall before the alarm, not during it, and write down when the water goes home."* **Wrong-but-reasonable:** "The air tank is at 6 of 10; that is plenty for one night." The preview shows seven shifts of breathing at −1 each bringing air to zero before dawn, Amara's poll turns `NO-GO [FR-02]`, and nothing is committed. A second: "Fill the wall to 6 now while there is daylight": the preview shows `W ≥ 4` thirst costing Alo and the crop every shift.

**3 · Decision and escalation (the NASA way).** Each shift opens the 23 §1.3 trade-study card with Preview A and Preview B side by side; `FR-01`..`FR-04` are badged; the four-role Go/No-Go poll must read GO or GO WITH ADVISORY before Commit; the drill follows a no-cost ODF card. Risk cards: thirst at 5 × 3 and blackout at 5 × 4 (23 §7.2). Commit order is canon: shift 1 in S07, shift 2 only after the drill in S08, shifts 3–4 in S09. **Escalation:** S07 abundance (where should overflow go?) → S08 a safe rehearsal of the coming danger (Portal) → S09 sunset and the loss of Earth's voice. **Set piece:** the mast stops producing, `CUE-03` "Last Light" plays, the crew reads back Ferreira's instruction, `SFX_RADIO_EARTH_LOST` closes the channel and the Earth button greys out with a `STORED GUIDANCE` label. Fans continue at the lower night pitch; Kai reaches towards the hand light, then opens the plan. **Outcomes:** *success*: shifts 1–4 committed with no blackout, the forecast keeps `A > 0` to dawn, the wall is staged before the alarm and its return is scheduled. *Partial*: the committed plan passes with a known amber (Mei's `ADVISORY: W ≥ 4` accepted, or the jar forecast to sit at exactly `E0`, which 08 counts as "not a blackout"). *Failure*: a commit that would bring `A ≤ 0` triggers the pre-loaded `FR-02` abort and restores the pre-shift checkpoint (23 §2.2); a negative energy balance is allowed but its blackout penalties are shown first (08).

**4 · Hints.** 08 P-02: H1 "Store air while sunlight would overflow." · H2 "Prepare shielding before the alarm, then return the water." · H3 "Open the worked Bloom plan or Guided plan." **Modes:** Family has the Guided plan and no timers; Engineer adds kg O₂, kWh and g/cm² subtitles with their tags; Class runs the real role-card hand-off at shifts 1, 2 and 3.

**5 · Playtime and feel.** 6 + 6 + 6 minutes. *Hands:* drag energy tokens between jar, air maker and lamp; turn the heat dial (COZY / COOL / COLD) and the lamp switch (OFF / DIM / FULL); open and close the transfer valve in the drill; count people through the doorway. *Ears:* `SFX_FAN_NORMAL` stepping down to `SFX_FAN_LOWPOWER`, `SFX_WATER_TRANSFER` in the drill, `CUE-03`, then the quiet after `SFX_RADIO_EARTH_LOST`.

### 3.4 `EX-M0104` — Keep the Promise Until Dawn

`EX-CH01-S10`..`S12` · Safe Room and response controls, garden service line, chamber shutter and Tara reference bay · **P-02** shifts 5–7 and the ending · **21 min** · Data Cards: `donki_2017_09` and `goes13_protons_2017_09` (X8.2 flare 10 Sep 2017, >10 MeV onset 70 minutes after flare start `[M]`; east-facing detector’s second 7.2 h had 1.6× the flux, debrief only), `clowdsley_2021_shielding` · Outpost Status: Shielding `S = min(6, W + K)` and exposure `Z` take centre stage; the `Z ≤ 3` limit is badged.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Particle alarm with its replay label (`10 Sep 2017 · historical replay`), an instrument trace, not projectiles. | INS + CARD | Safe Room (S10) | R |
| 2 | Shelter readout `S = W + K` against the dose table: S 0–1 → 3, 2–3 → 2, 4–5 → 1, 6 → 0 per storm shift (08). | INS | Response panel | All |
| 3 | `EX-CH01-S10-L04` Amara: "One exclusive response. Its cost is in the forecast." | DLG | S10 | A |
| 4 | `EX-CH01-S11-L02` Amara: "Exposure resolves before drain. Read the gate." (08: shift-6 exposure uses shelter at the start of the shift). | DLG + INS | Garden line (S11) | A |
| 5 | Battery approaching zero; `EX-CH01-S11-L03` Kai: "Low is not failed. What demand comes next?" (exactly `E0` is not a blackout) | INS + DLG | Mission table (S11) | K |
| 6 | Chamber conditions panel before the shutter; then N.'s stored recording, `EX-CH01-S12-L02`: "If you are hearing this, Alo bloomed. Good. Now Alo needs a friend." | INS + LOG | Shutter and bay (S12) | M, then All |

**2 · Deduction.** Read the current `S` against the dose table: if preparation already reached `S ≥ 4`, WAIT is a legitimate strategy (08); if not, choose one exclusive intervention. **Aha:** *"Our preparation already did the work; waiting is a decision, not doing nothing."* Then: *"The water may only come home after the exposure it was shielding."* **Wrong-but-reasonable:** Kai's `EX-CH01-S10-L02` "I can do another action." The panel allows one of PUMP, STACK or WAIT; quick clicks cannot collect several, and Mei's read-back (`EX-CH01-S10-L03`, "Read this one back first.") turns the impulse into a team decision. A second: draining at the start of shift 6 to rescue the garden; the preview shows shift 6 scored with the smaller shield.

**3 · Decision and escalation (the NASA way).** The alarm card is exactly 23 §1.3's example (PUMP / STACK / WAIT columns with power, consumables, risk and crew time). `FR-03` is pre-ticked and locked: "Crew into Safe Room: required (flight rule)". The four-name roll call precedes any exposed commit (`EX-CH01-S10-L01`). PUMP runs its three valve confirmations, STACK its four-bundle placement (08). Risk card: "Unshielded storm shift" 5 × 5, HIGH. **Escalation:** S10 the crisis inside the rules → S11 recovery on a nearly empty battery, where "low" must not be read as "failed" → S12 dawn, where the last task is a safety check, not applause. **Set piece:** the first strip of returning light meets the closed shutter; after the chamber check `SFX_SHUTTER_OPEN` reveals the yellow flower, `CUE-04` "First Flower" plays, and tagging the photograph starts N.'s recording with `SFX_RECORDER_AGED`. Through the night Alo's leaves curl with each cold or thirsty shift and lift at first light. **Outcomes (08 endings):** *Golden Bloom* (three stars and `H ≥ 5`): the flower fully open and the cue resolves. *Bloom* (safe crew, `H > 0`): the flower opens; any missed star is explained in the debrief. *Alo lost* (safe crew, `H = 0`): no flower, a respectful closure and causal review; the story does not advance and the full checkpoint is offered. *Mission stopped* (`A ≤ 0` or unsafe exposure): the pre-loaded flight rule ends operations; the last-shift checkpoint restores everything.

**4 · Hints.** 08 P-02 H1–H3 as in 3.3; after a first Bloom, G1 "Golden needs Alo at 5 or more with no blackout, so every drop must reach the garden at exactly the right time." · G2 "Open the worked Golden plan." **Modes:** Family removes the PUMP and STACK timers (same confirmations, untimed); Cadet uses 08's 15 s / 30 s tasks with assisted input always available; Engineer shows Clowdsley's real dose curve (185 → 85 mSv between 5 and 15 g/cm², never zero) beside the game table, labelled `SIMULATED [G]`.

**5 · Playtime and feel.** 7 + 7 + 7 minutes. *Hands:* roll-call taps, three valve wheels (PUMP) or four bundles carried into bunk outlines (STACK), the drain valve after the exposure gate, the shutter lever, the camera button on the bloom. *Ears:* `SFX_ALERT_PARTICLE`, `SFX_HATCH_SEAL`, cabin breathing and fans only, `SFX_PUMP_PRESSURE` or bundle thuds, near-silence at low battery, then `CUE-04` and N.'s aged voice.

---

## 4. Chapter 2 — *Be the Bee* (`EX-M0201`–`EX-M0204`)

Chapter question: how do you replace a missing pollinator without breaking containment, and how do you treat an old record honestly? Mastery (10_GAMEPLAY_SYSTEMS): safe procedure, no blackout, three reciprocal runs; Golden adds no contaminated transfer.

### 4.1 `EX-M0201` — Understand the Missing Bee

`EX-CH02-S01`..`S03` · Tara reference bay and Earth console, indoor botanical bench, garden service corridor and transfer interlock · **P-03** protocol, structures and route · **18 min** · Data Cards: `fast_plants_lifecycle` (self-incompatible; stigma receptive 2–4 days; pollinate 15–21 days after planting `[M]`), `mir_brassica_seed_to_seed` (full *Brassica rapa* life cycles completed on Mir `[M]`), `donki_2017_09` (what a space-weather check reads) · Outpost Status: entry `E14/20, A10/10, H6, C8, R18` (08); the route preview shows `E1/A1` per whole reciprocal cycle.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Tara's and Alo's identity cards: both compatible individuals of the same mustard cultivar, which is self-incompatible. | OBJ + CARD | Tara bay (S01) | M |
| 2 | `EX-CH02-S01-L01` Ferreira (Earth link): "You did not just endure the night. You operated it." (contact returns 30 April, after the stored recording) | DLG | Earth console (S01) | All |
| 3 | Rafi's paper bee beside the protocol; `EX-CH02-S02-L02` Mei: "Good. What does it actually do?" | OBJ + DLG | Bench (S02) | R |
| 4 | Magnified flower images with word-and-shape labels: anther (pollen) and stigma. | INS | Bench (S02) | M |
| 5 | Two clean brushes labelled A and B; `EX-CH02-S02-L03` Amara: "One brush for each recorded direction." | OBJ + DLG | Bench (S02) | A |
| 6 | Kai's sketch, a straight line Tara → Alo, laid over the station diagram with doors and pressure boundaries; `EX-CH02-S03-L02` Rafi: "It left out the air." | OBJ + DLG | Service corridor (S03) | K |
| 7 | Space-weather status panel, checked before any run. | INS + CARD | Interlock (S03) | R |
| 8 | Route-charge preview; `EX-CH02-S03-L03` Amara: "Count the whole reciprocal cycle once, not every camera cut." | INS + DLG | S03 | A |

**2 · Deduction.** A flower of this cultivar needs pollen from its partner; the bee's job is to move pollen from one plant's anther to the other plant's stigma, in both directions, keeping each direction's record and each chamber's atmosphere. **Aha:** *"We don't move the plants; we move the pollen, sealed, with one labelled brush per direction."* **Wrong-but-reasonable:** Kai's "put the two chambers together" (S01 prose): Amara points to separate services and purposes and the preview shows how many variables change at once. Then "one brush is enough", the first canon option in S03: the paused model loses donor attribution and flags the cleaning failure before any living flower is touched.

**3 · Decision and escalation (the NASA way).** Trade-study card "Which transfer design preserves both containment and attributable evidence?" (the S03 decision review): one unlabelled brush versus separately labelled clean tools in a closed carrier, scored on containment, attribution, crew time and the `E1/A1` cycle charge. `FR-06` (containment; space-weather check before each run) is badged. ODF route card: weather check → carrier latch → one boundary at a time (two boundaries can never open together) → return leg. Risk card: "Boundary opened with the next one open", 2 × 5, HIGH, blocked by interlock. **Escalation:** S01 wonder (a second flower) → S02 a rehearsal on a nonliving model (Portal) → S03 the real route with doors, pressure and a return leg. **Set piece:** Tara opens while the Earth console lights; Ferreira's praise arrives with `SFX_RADIO_EARTH_IN` and its latency texture; at the end of S03 the last practice boundary closes and both chamber pressure indicators stay unchanged. **Outcomes:** *success*: protocol opened, structures and directions matched on the model, route and single cycle charge confirmed. *Partial*: a model placement was corrected after its explanation. *Failure*: opening a second boundary or committing the one-brush design is refused in the model; no flower is touched.

**4 · Hints.** 08 P-03: H1 "A flower needs pollen from its partner." · H2 "Take pollen from the anther to the other plant’s stigma." · H3 "Use A for Tara→Alo and clean B for Alo→Tara." **Modes:** Family identifies structures by tapping word labels; Engineer shows the Fast Plants window (pollinate days 15–21 `[M]`) against the planned run dates (plant days 19–25 `[F]`).

**5 · Playtime and feel.** 6 + 6 + 6 minutes. *Hands:* set the paper bee on the bench, tap anther and stigma on the magnified image, lay brushes A and B on their labels, latch the carrier, trace the route boundary by boundary. *Ears:* Earth-link latency, `SFX_DOOR_LATCH`, `SFX_AIRLOCK_CYCLE` in practice, `CUE-02`.

### 4.2 `EX-M0202` — Carry the Future Carefully

`EX-CH02-S04`..`S06` · Tara bench, transfer route and Alo glove ports, paired care stations, paired observation bench · **P-03** three reciprocal runs and the prediction · **18 min** · Data Cards: `fast_plants_lifecycle` (pods mature about 20 days after pollination `[M]`), `mir_brassica_seed_to_seed` · Outpost Status: each run charges `E1/A1` once; after the three sampled operations 08's witness is `E16, A4, H9, C10, R14.4`.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Donor and recipient scans; `EX-CH02-S04-L01` Amara: "Donor Tara. Recipient Alo. Read the second label." | INS + DLG | Tara bench (S04) | A |
| 2 | Pressure confirmations at each interlock. | INS | Transfer route (S04) | R |
| 3 | Contact image and date; `EX-CH02-S04-L04` Amara: "The transfer did. Seeds are a later observation." | LOG + DLG | Alo glove ports (S04) | M |
| 4 | The seven-date strip with three bee-run marks (30 April, 3 May, 6 May); `EX-CH02-S05-L03` Mei: "Both plants get care every day. Pollen runs have their own schedule." | OBJ + DLG | Care stations (S05) | M |
| 5 | Fresh weather check before each actual run; `EX-CH02-S05-L04` Rafi: "Weather check before each actual run. Familiar is not automatic." | INS + DLG | Interlock (S05) | R |
| 6 | Alo's purple stem and Tara's green stem, both with text labels. | OBJ | Observation bench (S06) | M |

**2 · Deduction.** Three things must line up: the protocol order (Tara anther → sealed brush A → Alo stigma; Alo anther → clean brush B → Tara stigma), the schedule (seven care dates, exactly three reciprocal cycles), and the claims (procedure success is not a biological result; a prediction is not a promise). **Aha:** *"Care happens every day; pollen runs have their own dates."* And in S06: *"A prediction is useful because it says what would surprise us."* **Wrong-but-reasonable:** return each plant's pollen to its own stigma (S04's first option): the comparison explains self-incompatibility and nothing is damaged. Repeat a transfer at every visit "to be sure": the ledger shows an extra `E1/A1` per cycle and the record still needs exactly three. Kai's confident `EX-CH02-S06-L01` "Purple and green. So the children will be..." gets Amara's `EX-CH02-S06-L02` "A prediction. Finish it as a prediction."

**3 · Decision and escalation (the NASA way).** Each run is an ODF checklist (scan donor → brush A → seal → interlock → scan recipient → contact → reverse with brush B → record) with Rafi's space-weather GO required every time (`FR-06`). The prediction is a pre-registered test criterion: the player writes the expectation, a reason and "what would count as a surprise" before any outcome exists, and the original entry can never be overwritten. Risk card: "Contaminated transfer", 3 × 3, MODERATE (it is also the chapter's Golden criterion). **Escalation:** S04 the first real run on living flowers → S05 repetition with variation and a growing energy ledger (Witness) → S06 the intellectual stake of being wrong in public. **Set piece:** the close-up of one brush contact (`SFX_BRUSH_CONTACT`) and then *no* shower of seeds; in S06 a thread draws itself from the dated prediction to the family-tree page. Alo stands upright with open flowers; Tara gets equal framing. **Outcomes:** *success*: three valid reciprocal cycles on their dates, seven care entries, a dated prediction with its reason and surprise criterion. *Partial*: a transfer was redone (a petal touch moves no pollen, 08) or a tip was replaced; Golden is lost only if a stigma was touched by a brush carrying the wrong donor's pollen. *Failure*: a run without a weather check or with two boundaries open is refused; nothing is charged; unlimited clean tips (08).

**4 · Hints.** Runs: 08 P-03 hints as in 4.1. Prediction (`NEW`): H1 "What can two stem colours tell you, and what can't they?" · H2 "Write what you expect and what would surprise you." · H3 "Example of the format: 'Both colours may appear. A surprise would be every plant one colour.'" **Modes:** Family transfers by select-confirm; Engineer shows the plant-day arithmetic and labels the prediction panel "no genotype ratio is claimed".

**5 · Playtime and feel.** 6 + 6 + 6 minutes. *Hands:* brush pick-up, glove-port contact, carrier in its cradle, a bee stamp on each date (Kai's crooked one stays), writing the prediction. *Ears:* `SFX_BRUSH_CONTACT`, `SFX_GLOVE_PORT`, `SFX_AIRLOCK_CYCLE`, `CUE-02`.

### 4.3 `EX-M0203` — Make an Old Record Useful

`EX-CH02-S07`..`S09` · Mission table, recorder service bench, local evidence reconstruction board · **P-04** metadata · **18 min** · Data Cards: `apollo_shallow_moonquakes` (a real NASA PDS archive labels every record with date, instrument and channel; P-04's tokens are `[F]`), `fast_plants_lifecycle` · Outpost Status: steady (no resource decision); the Journal's Evidence Board is the main screen.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Three stage images: a young unflowered seedling with curled leaves (old trial), today's pollinated flower, a reference illustration of mature pods. | OBJ | Mission table (S07) | M |
| 2 | The paper bee's wing brushes the recorder; `EX-CH02-S07-L04` Rafi: "This equipment number matches the old trial card." | OBJ + DLG | S07 | R |
| 3 | A lifted corner of the newer service sticker over an older plate; `EX-CH02-S08-L02` Mei: "Photograph it. Do not peel the only original." | OBJ + DLG | Service bench (S08) | K |
| 4 | Photographed source labels: device plate `HORT-01`, maintenance date `2034-04`, channel label `ENGINEERING` (08 tokens). | LOG | S08 | K (plate), M (date), A (channel) |
| 5 | The old trial-stage chart: reproductive stage not reached; `EX-CH02-S08-L04` Rafi: "And a seedling record is not a previous flower." | LOG + DLG | S08 | M |
| 6 | Three recorder files: A lacks a date, B lacks a device, C lacks a channel (08). | LOG | Reconstruction board (S09) | A |
| 7 | A tempting card naming a possible owner, excluded until evidence exists; `EX-CH02-S08-L03` Amara: "A device match is not a person’s name." | OBJ + DLG | S08 | All |

**2 · Deduction.** Separate three questions (which device, when, what stage did the trial reach) and give each one supported answer from its own source. **Aha:** *"A device match is not a name. The person's slot stays empty, and that is the honest board."* (Obra Dinn's blank face, here a blank card.) **Wrong-but-reasonable:** "An earlier flowering garden makes Alo's first bloom false." It is S08's first option; the chart and the seedling record contradict it and the player narrows the claim. Kai's `EX-CH02-S09-L02` "Can I name the file after my guess?" is answered by Mei's `EX-CH02-S09-L03` "Name it after the evidence first." Peeling the sticker is never offered as an action; the camera is.

**3 · Decision and escalation (the NASA way).** An ODF verification card (23 MP-04): match date, device and channel → checksum the copy → only then unlock playback; the original stays untouched while the player works on a local copy. MER step 2 (23 §7.3): verify against an independent source (the plate) before trusting a label. Rafi's read-back proves repeatability (`EX-CH02-S09-L04`). Risk card: "Original evidence destroyed", 2 × 4, MODERATE, removed by "photograph, don't peel". **Escalation:** S07 patience (a plant cannot be pulled into the future) → S08 discovery under a label → S09 the locked playback, earned by evidence. **Set piece:** when the third token seats, the playback button lights for the first time and the room's bench lamp narrows onto the recorder; the board keeps one clean empty slot where a person might belong. **Outcomes:** *success*: three tokens matched, intact local copy with an evidence-based file label and replayable steps. *Partial*: a wrong token was placed and removed after the board named the disagreeing source (08). *Failure*: none; audio stays locked until all three match, and evidence persists through reset (08).

**4 · Hints.** 08 P-04: H1 "Find the original equipment plate." · H2 "Dates, devices and channels are different fields." · H3 "2034-04, HORT-01, ENGINEERING." Life-cycle order (`NEW`): H1 "Which picture is from our garden, and which only shows what comes later?" · H2 "Flowers, then pods, then drying, then harvest." · H3 "Flower (ours, now) → mature pods (reference only) → harvest (later)." **Modes:** Family uses the accessible table view (S09's second option); Engineer shows a PDS-style label (`date / instrument / channel`) beside the tokens.

**5 · Playtime and feel.** 6 + 6 + 6 minutes. *Hands:* order stage cards, frame the plate with the camera, pin cards and pull string on the board, slot three distinct token shapes. *Ears:* `SFX_CAMERA_SHUTTER`, the bench hum, paper and pins, `CUE-02` low.

### 4.4 `EX-M0204` — Hear, Ask and Reprioritise

`EX-CH02-S10`..`S12` · Recorder playback station, Earth-link console, interior brace zone · **P-04** playback and send; the quake · **21 min** · Data Cards: `apollo_shallow_moonquakes` (south-polar shallow quake, 13 March 1973, magnitude 3.2 on the catalog's scale `[M]`) · Outpost Status: steady until the quake; then Life support shows a new red pressure warning, recorded but not acted on.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | `EX-CH02-S10-L01` Engineer (stored 2034 recording): "Biological trial suspended. Crew retreat is mandatory." | LOG | Playback station (S10) | All |
| 2 | `EX-CH02-S10-L03` N. (stored 2034 recording): "My grandmother’s mustard fields turned yellow every winter. I wanted some of that light here." | LOG | S10 | All |
| 3 | `EX-CH02-S10-L02` Kai: "That sounds like Ferreira. Younger, maybe." | DLG | S10 | K |
| 4 | The transmit queue: copy, source images, checksum, transcript; a receipt column apart from a replies column; `EX-CH02-S11-L03` Amara: "Delivered is not the same as answered." | INS + DLG | Earth-link console (S11) | R (package), A (receipt) |
| 5 | A cup at the mission table beside the pending-reply indicator; it begins to tremble. | OBJ | S11 end | All |
| 6 | Local structural alarm, brace-zone floor markings, four name tokens. | INS | Brace zone (S12) | R |
| 7 | A newly displaced service cover (`EX-CH02-S12-L02`) and one atmosphere indicator turned red (`EX-CH02-S12-L04`: "Here. Pressure warning changed. We verify the reading next."). | OBJ + INS | S12 | K (cover), A (indicator) |

**2 · Deduction.** First, classify: a recorded instruction is Observed; a voice that resembles someone is Inferred; the writer's identity is Unknown. Then, in S12, reprioritise: people first, and a new warning is something to investigate, not something to act on blindly. **Aha:** *"Sounding like someone is an inference; the date on the file is a fact."* **Wrong-but-reasonable:** treat the resemblance as proof (S10's first option): the board flags that sound alone cannot establish a personal history. Add a guessed name to the package: Mei removes the line (`EX-CH02-S11-L02`, "Leave the name as a question."). During the shaking, head back to the garden controls: the game blocks the detour and states why (the plants are in serviced chambers). After it, "the indicator says tank, close the tank valve": Amara's line defers action to verification, which is Chapter 3.

**3 · Decision and escalation (the NASA way).** Communication states follow 23 MP-08: the package is assembled, sent, receipted and kept apart from any reply (CAPCOM-style closed loop). The quake response is `FR-01` crew first with a four-name roll call (`EX-CH02-S12-L01`); no dexterity timer. Risk card: "Aftershock while the crew is dispersed", 3 × 5, HIGH (23 §7.2 lists the P-05 aftershock at the same rating). **Escalation:** S10 intimacy (two voices from 2034) → S11 anticipation (waiting for a reply) → S12 interruption: the stakes switch from a mystery to the crew's safety in one beat (Firewatch). **Set piece:** the cup on the table (T9) starts to tremble with `SFX_CUP_RATTLE`, then `SFX_QUAKE_CONTACT` comes up through the floor and `SFX_ALERT_STRUCTURAL` sounds; Mei looks once at the pending reply and closes that panel. The chapter ends on a red indicator and no time jump. **Outcomes:** *success*: both fragments heard or read and classified, the package sent without an unsupported identity, the evening handover finished, four braced. *Partial*: the package was sent only after a guessed line was removed, or a voice was first filed under Observed and moved. *Failure*: none; the roll call waits for all four and the detour is blocked.

**4 · Hints (`NEW`).** Classification: H1 "Which statements did someone actually record, and which are our guesses?" · H2 "A voice that 'sounds like' someone goes under Inferred." · H3 "Example: 'Retreat ordered, 2034' → Observed. 'Voice resembles Ferreira' → Inferred. 'Writer's name' → Unknown." Quake: H1 "What changed in the room?" · H2 "People first: brace zone, four names." · H3 "Move each token into the brace zone, confirm four answers, then record the red indicator for checking." **Modes:** Family has no timer at any point (canon); Engineer shows the Apollo catalog row and states which magnitude scale it uses (SCIENCE_AND_DATA §B3, related claim).

**5 · Playtime and feel.** 7 + 7 + 7 minutes. *Hands:* scrub the playback timeline, drag statements into three columns, tick files into a package, set the cup down, move tokens into the brace zone. *Ears:* `SFX_RECORDER_AGED`, two archive voices, Earth-link send tone, a long quiet, `SFX_CUP_RATTLE`, `SFX_QUAKE_CONTACT`, `SFX_ALERT_STRUCTURAL`, then `SFX_ALERT_PRESSURE` as the last sound of the chapter.

---

## 5. Chapter 3 — *Moonquake* (`EX-M0301`–`EX-M0304`)

Chapter question: how do you act on a warning you do not yet trust, and how do you let a living process finish? Mastery: at most one wrong isolation, no blackout, live seed harvest; Golden adds no wrong isolation.

### 5.1 `EX-M0301` — Find the Falling Line

`EX-CH03-S01`..`S03` · Atmosphere service corridor, diagnostic taps, isolation preview board · **P-05** investigation · **20 min** · Data Cards: `apollo_shallow_moonquakes` (the real south-polar shallow quake of 1973 `[M]`), `bvad_2022_metabolic` (101.3 kPa nominal; air unit = four-crew O₂ `[C]`) · Outpost Status: 08 entry `E14/20, A10/10, H6, C8, R18`; four investigation phases (abstract budget, no story hours, Handbook §3 4 Nov) at DIM/O0, basic `E1` and light `E1`, breathing `A1` per phase plus the unresolved leak `A1` per phase in phases 1–3; at most two location inspections per phase.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | The main panel's oxygen-tank symbol is red and its diagnosis reads `TANK`; `EX-CH03-S01-L01` Amara: "The panel says tank. I do not trust the diagnosis yet." | INS + DLG | Service corridor (S01) | A |
| 2 | The independent mechanical gauge on its hook, with a reference-position check; `EX-CH03-S01-L03` Rafi: "Gauge first. A colour is not a pipe." | OBJ + DLG | S01 | R |
| 3 | `EX-CH03-S01-L04` Mei: "The plants keep their own sealed atmosphere while we check the room feed." | DLG | Garden panel (S01) | M |
| 4 | Three tap readings at t0 / t10: `MAIN 100/100`, `GARDEN 82/74`, `RETURN 100/100` (08 relative test units). | INS | Diagnostic taps (S02) | A reads, K traces |
| 5 | Simplified piping diagram with six candidate locations: main tank, habitat trunk, garden feedthrough, return line, airlock seal, annex branch (08; `NEW` diagram labels). | OBJ | S02 | All |
| 6 | Phase 2 aftershock: the annex branch's automatic isolation indicator flips and must be verified before the garden reopens (08). | INS + CARD | S02–S03 | R |
| 7 | `EX-CH03-S03-L03` Ferreira (Earth link): "Repair diagram sent. Safety information does not wait." Kai checks it against the physical labels (`EX-CH03-S03-L04`). | DLG + OBJ | Isolation board (S03) | All, then K |

**2 · Deduction.** A hypothesis has to explain all three taps: the main tank holds, the garden spur falls, the return holds, so the fault sits on the garden spur and the panel's `TANK` is a diagnosis, not a measurement. The inspection budget (two locations per phase) makes the player choose *which* candidates to check first; every candidate must still be cleared within four phases. **Aha:** *"The tank holds at 100. The red symbol was the panel's guess; the falling line is the garden branch."* **Wrong-but-reasonable:** Kai's `EX-CH03-S01-L02` "Can we close the red thing?" (the main tank): `FR-02` raises the Protected Reserve Warning and the valve reopens at once (08). Kai's upstream fault location in S02 explains one tap and contradicts another (`EX-CH03-S02-L02`: "It does not. Keep that observation."). In S03, closing the whole habitat trunk is a valid-looking boundary that the preview shows removing far more service than the evidence supports.

**3 · Decision and escalation (the NASA way).** The full five-step MER workflow (23 §7.3): safe the crew → independent instrument → fault tree across the six candidates → plan a safe-side repair → define multi-sample verification. Trade-study card "Which isolation is justified?" (trunk versus spur) with a mandatory **rollback condition** field (Rafi marks it, S03). Go/No-Go poll before any valve moves (23: P-05); `FR-02` protects `MAIN`. Risk cards: garden leak 4 × 3 HIGH, closing `MAIN` 2 × 5 HIGH, aftershock 3 × 5 HIGH. **Escalation:** S01 uncertainty admitted out loud → S02 the aftershock arrives mid-investigation and adds a sixth state to verify → S03 a proportionate plan with Earth's diagram, checked against the room. **Set piece:** the aftershock in S02 is the chapter's echo of S12: the same cup rattles on the table, `SFX_QUAKE_CONTACT` comes through the floor, and the annex auto-isolation indicator flips; nobody runs. The red symbol pulses only on its panel while room light stays normal and the fans keep going: calm competence. **Outcomes (mastery):** *success / Golden*: spur isolation approved with rollback and no wrong isolation committed. *Partial*: one wrong isolation was committed and safed (star kept, Golden lost). *Failure*: a committed unsafe trunk isolation safes the station and retries from the gauge checkpoint (08); planning pauses the leak, so thinking is never punished.

**4 · Hints.** 08 P-05: H1 "Which reading changes over time?" · H2 "Compare the manual garden reading." · H3 "Close GARDEN, clamp its feedthrough, reopen and verify five steady readings." **Modes:** Family pauses each phase automatically and shows the inspection budget as two tokens; Engineer shows the gauge as relative test units with the pending proposal to label 100 as 101.3 kPa (SCIENCE_AND_DATA §B3-7, not yet approved) and the Apollo catalog row.

**5 · Playtime and feel.** 6 + 7 + 7 minutes. *Hands:* lift the gauge off its hook, zero it, clip it to each tap, finger-trace the piping diagram, place a chalk-line isolation boundary on the paused preview. *Ears:* fans unchanged, the needle's tick, one `SFX_ALERT_PRESSURE` acknowledged then muted, `SFX_QUAKE_CONTACT` and `SFX_CUP_RATTLE` at the aftershock, Earth-link latency for the diagram.

### 5.2 `EX-M0302` — Repair Before Discovery

`EX-CH03-S04`..`S06` · Garden service spur, atmosphere console, isolated annex viewing port · **P-05** repair and verification; the annex camera (P-06's map thread begins) · **21 min** · Data Cards: `bvad_2022_metabolic`, `apollo_shallow_moonquakes` · Outpost Status: the leak's `A1` per phase stops once sealed; 08's witness ends `E18, A3, H6, C8, R13.2`.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Isolated GARDEN holds at 74 while MAIN stays 100 (the hold check before clamping, 08). | INS | Garden spur (S04) | A |
| 2 | The captive clamp latches only from the pressurised safe side, never on a pressurised leaking connection (08); `EX-CH03-S04-L01` Kai: "Clamp seated. That is not the same as verified." | OBJ + DLG | S04 | K |
| 3 | Five consecutive 2-second readings, 100/100/100 (08). | INS | Atmosphere console (S05) | A |
| 4 | A copied note that disagrees with the tested valve position; `EX-CH03-S05-L02` Kai: "The note is wrong. The tested valve position is right." | OBJ + DLG | S05 | K |
| 5 | Plant-chamber record stable throughout the isolation (`EX-CH03-S04-L04`). | INS | Garden panel | M |
| 6 | The displaced floor cover exposes a service hatch marked `N.R.`; the station's certified plan already shows the isolated annex. | OBJ + LOG | Annex hatch (S06) | R |
| 7 | Camera view through the viewing port: tray silhouettes, a damaged growth chart, an old route marker under a clear cover. | INS | Viewing port (S06) | All |

**2 · Deduction.** A completed hand movement is not a verified repair; a paper note must agree with the tested system, not the other way round; seeing a room is not permission to enter it. **Aha (S05):** *"When the note and the tested valve disagree, fix the note."* **Aha (S06):** *"The annex was on the plan all along; what's new is a door we can see."* **Wrong-but-reasonable:** "The clamp animation finished, so reopen" (S04's first option): the test rejects position alone. "Change the valve to match the note" (S05's first option): the preview flags reversing a verified safe state. "Enter the annex now" (S06's second option): the gate refuses; suited entry is scheduled for 8 May after extended checks.

**3 · Decision and escalation (the NASA way).** The ODF repair card from 23 §4.3 (isolate GARDEN → ✓ MAIN 100 and GARDEN 74 → fit clamp from safe side → reopen slowly → ✓ five 2-second readings 100/100/100), with Amara reading each step back from the safe console and Rafi confirming the work boundary (`EX-CH03-S04-L02`, `L03`). Reopening needs a Go/No-Go with Mei's GO on the plant chamber. The aftershock's annex isolation must be verified before the garden reopens (08). Documentation fixes are signed (MP-04 configuration control). Annex access follows a boundary check card: feed isolated → pressure boundary verified → port opened → camera first. **Escalation:** S04 hands on a live system → S05 the quiet room, where the job is to prove nothing changed → S06 the hook: `N.R.` on a real door. **Set piece:** S04's slow reopen with the gauge needle climbing to 100 and *holding*; S05 ends with Amara hanging the gauge back on its hook (`EX-CH03-S05-L01`); S06 cuts to the camera feed in cold blue light as `CUE-05` "Unfinished" begins, while Rafi's hands stay on the camera controls. Alo, in her own sealed chamber, stands unaffected with flowers giving way to early pods. **Outcomes:** *success*: P-05 completion trigger met (six candidates within four phases, annex isolation verified, five stable readings), note corrected and signed, camera view saved and port closed. *Partial*: the practice reopening trend failed once and the procedure returned to the diagnostic boundary before passing. *Failure*: a clamp on the wrong side cannot latch; a fast reopen fails its trend and returns to the boundary; nothing is harmed.

**4 · Hints.** Repair: the 08 P-05 hints above. Note (`NEW`): H1 "Which record was tested: the note or the valve?" · H2 "Keep the tested state; correct the paper." · H3 "Strike the copied value, write the verified valve position, sign and date it." Annex (`NEW`): H1 "Is seeing a room the same as being allowed in?" · H2 "Isolate the feed and check the boundary before the port opens." · H3 "Feed OFF → boundary reading stable → open port → camera only → save view → close port." **Modes:** Family reopens with an assisted slow-turn (no fine motor control); Engineer shows the five readings as a time series.

**5 · Playtime and feel.** 7 + 7 + 7 minutes. *Hands:* close the spur valve, seat the clamp, turn the reopen wheel slowly, tap five checks, cross out and sign the note, unscrew the port cover, pan the camera. *Ears:* `SFX_VALVE_DETENT`, `SFX_CLAMP_SEAT`, the needle, a quiet console, then the first bars of `CUE-05`.

### 5.3 `EX-M0303` — Read What Was Unfinished

`EX-CH03-S07`..`S09` · Cold annex and warm-side support station, annex chart archive and evidence table, garden maturity and drying bench · **P-06** map provenance, maturity and dry-down · **21 min** · Data Cards: `fast_plants_lifecycle` (pods mature about 20 days after pollination; seeds about 40 days after planting `[M]`), `mir_brassica_seed_to_seed`, `change4_cotton` (a real trial that ended at the seedling stage) · Outpost Status: Food (`H` for Alo) is the focus; 08 P-06 starts on 16 May (plant day 35) with moisture 70 and the drying valve open.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Frozen trays: young seedlings with curled leaves, none flowered; `EX-CH03-S07-L01` Mei: "I mistook the curled leaves for flowers. They were young seedlings." | OBJ + DLG | Cold annex (S07) | M |
| 2 | The damaged growth chart; `EX-CH03-S07-L02` Amara (local link): "The growth chart agrees: seedling stage." | LOG + DLG | S07 | A |
| 3 | A service tag dating the trial to 2034; the route sheet filed before evacuation. | LOG | S07 | R |
| 4 | The route sheet to a permanently shadowed survey site with a marked storage deposit; `EX-CH03-S08-L03` Amara: "The deposit date is earlier than the retreat." | LOG + DLG | Chart archive (S08) | R (map), A (date) |
| 5 | Dated care visits 8–16 May: pods developing on the living plants. | LOG | Garden (S08) | M |
| 6 | Maturity camera and chart, moisture profile at 70 (08). | INS | Drying bench (S09) | M |
| 7 | `EX-CH03-S09-L03` Amara: "This is maturity, not the old cold alarm." | DLG | S09 | A |

**2 · Deduction.** S07: expectation biases observation; two independent records (material and chart) agree on the seedling stage. S08: a map is evidence that somebody planned a journey, not certification that today's rover can repeat it. S09: Alo is finishing her life cycle; maturity is not a fault, and pods open only after a controlled dry-down. **Aha:** *"Alo isn't failing. She's finishing."* **Wrong-but-reasonable:** "an earlier flowering garden" (S07's first option) is rejected by both records. Kai's `EX-CH03-S08-L01` "We have a map. Can we go now?" meets the planning board's missing slope, reserve and link checks. Kai's `EX-CH03-S09-L02` "Can we make the lamp help?" previews more light on a maturing plant and shows it changes nothing that matters. Opening pods immediately (S09's first option) runs only in the paused comparison. Turning irrigation off for the whole greenhouse names Tara's live supply and leaves it unchanged (08).

**3 · Decision and escalation (the NASA way).** Suited entry is an EVA-style Go/No-Go with a return condition read back before the scene lingers (Rafi, S07; `EX-CH03-S07-L04` Kai: "Return boundary ready when you are."). The map gets a trade-study card "What does the recovered map authorise?" scored on slope evidence, return reserve, communications and crew time, with the result filed as a *survey objective* plus three present-day checks. `FR-06` blocks the dry-down before maturity is confirmed and protects Tara's irrigation. Risk card: "Pods opened before drying", 3 × 4, HIGH. **Escalation:** S07 the most atmospheric scene of the chapter (suits, cold side, an unfinished garden) → S08 ambition versus patience → S09 the emotional stake: the plant everyone remembers is changing. **Set piece:** S07 is suit breathing and local radio only, frozen trays seen through a visor with no fog or haze; Mei leaves the tray as it is. In S09 Alo's posture tells the story: stem leaning, leaves yellowing, pods turning brown; never a face. The five-day interval is named on the date card before the player accepts it. **Outcomes:** *success*: entry and exit checks complete with seedling evidence saved undisturbed, map saved with its future checks, maturity verified and the Alo-only dry-down configured. *Partial*: the map was first pushed toward departure and redirected, or maturity was checked after a refused early harvest. *Failure*: none destructive; no interaction lets the player pull old seedlings apart, and early irrigation stop is blocked before maturity (08).

**4 · Hints.** Maturity: 08 P-06 H1 "Harvest after the pods mature." Map (`NEW`): H1 "What does the map prove, and what does it only suggest?" · H2 "List what a rover needs today that a 2034 map cannot promise." · H3 "Save the map as a survey objective with three checks: slope, return reserve, link chain." Annex account (`NEW`): H1 "Look at the leaves, then at the chart." · H2 "Two independent records should agree." · H3 "Curled leaves + chart 'seedling stage' → an interrupted seedling trial." **Modes:** Family paces the suited walk automatically; Engineer shows Fast Plants timing `[M]` against the 70 → ≤ 20 moisture target `[G]`.

**5 · Playtime and feel.** 7 + 7 + 7 minutes. *Hands:* suit check, slow walk on the cold side, photograph without touching, overlay the route sheet on the habitat plan, one observation per dated care visit, zoom the maturity camera, switch Alo's irrigation to OFF and set the drying valve. *Ears:* `SFX_SUIT_BREATH`, `SFX_RADIO_LOCAL_IN`, near-silence in the annex, `CUE-05` continuing, dry pods brushing the chamber glass.

### 5.4 `EX-M0304` — Let the Garden Continue

`EX-CH03-S10`..`S12` · Dry-harvest bench, garden planting rack and reserve store, dated maintenance and lineage board · **P-06** harvest and allocation; the five-month bridge · **23 min** · Data Cards: `fast_plants_lifecycle`, `mir_brassica_seed_to_seed` · Outpost Status: Food shows the founder reserve as its own protected line; resupply and maintenance ledgers carry the October bridge.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Final drying check: moisture ≤ 20 (08). | INS | Dry-harvest bench (S10) | M |
| 2 | Six pods over six counting wells, seven seeds each (08). | OBJ | S10 | All (counting is shared) |
| 3 | The ledger reconciliation `42 = 12 + 30`. | INS | S10 | A |
| 4 | The dry petal against the chamber wall, then sleeved. | OBJ | S10 | M |
| 5 | Lineage label; `EX-CH03-S11-L01` Amara: "Parent line first: Alo times Tara." | LOG + DLG | Planting rack (S11) | A |
| 6 | The sealed reserve container and its seal record; `EX-CH03-S11-L02` Rafi: "Thirty founder seeds remain sealed." | OBJ + DLG | Reserve store (S11) | R |
| 7 | Dated handovers 21 May → 21 October: generations, repeated pollination, resupply, procedures; the saved stem prediction attached to an October comparison; the map moved to a survey board (`EX-CH03-S12-L04`). | LOG | Lineage board (S12) | A, M, R |

**2 · Deduction.** Every physical seed is counted exactly once; names, albums and dedications are different records from the inventory; an annual plant's line continues through new generations, not one pot kept unchanged. **Aha:** *"These are descendants. Alo is in their lineage, not hiding in a pot."* (`EX-CH03-S12-L03` gives Mei the words.) **Wrong-but-reasonable:** a layout that double-counts one group (S10's second option) fails reconciliation before anything is sealed. Planting a thirteenth founder seed (S11's second option) is refused as an unrecorded draw. "The same plants just stayed for five months" (S12's first option) is rejected by the lineage and care records.

**3 · Decision and escalation (the NASA way).** The 12-versus-30 split is a trade-study card (23 P-06: active planting against a protected founder reserve) whose two allocation buttons commit it directly (08: "arithmetic dragging not required"). The harvest follows an ODF card (verify drying → open over the contained tray → count by wells → allocate → seal → label). Sealing the reserve needs Rafi's GO on the seal record and Amara's GO on the ledger. Risk card: "Founder seed lost or double-counted", 2 × 5, HIGH. **Escalation:** S10 grief and counting in the same breath → S11 continuation (the first new seed) → S12 the ordinary days that make the next expedition possible. **Set piece:** canon: "Small seed sounds replace the music for a moment": `CUE-05` drops out and forty-two `SFX_SEED_TICK`s fall into the tray; the final total is read aloud before any container leaves the bench. In S11 the first new seed gets the same close framing as Alo's planting in `EX-CH01-S04`, then the view widens to all four. S12's date cards end on 21 October with the garden larger and the corridor familiar. **Outcomes:** *success*: `42 = 12 + 30` sealed with petal and lineage archived, twelve positions planted, continuity ledger complete (the chapter's "live seed harvest" star). *Partial*: a miscount reopened one well before reconciliation (08). *Failure*: none destructive; seeds are never lost by cursor error (08).

**4 · Hints.** 08 P-06: H1 "Harvest after the pods mature." · H2 "Keep twelve for planting and thirty protected." · H3 "Six wells of seven total 42; allocate 12 and 30." Continuity (`NEW`): H1 "Can one annual plant last five months?" · H2 "Each tray is a new generation with its own dates and parents." · H3 "Link each October plant to its parent generation; keep the founder 30 on its own line." **Modes:** Family counts by tapping each well once (it auto-groups by seven, then asks for confirmation); Engineer shows the ~40-day seed-to-seed cycle `[M]` against the 21 May → 21 October interval.

**5 · Playtime and feel.** 7 + 8 + 8 minutes. *Hands:* tilt each pod over the tray, tap seeds into wells, move two back, seal the reserve, slide the petal into its sleeve, press twelve seeds into cassettes, write a dedication after the lineage label (`EX-CH03-S11-L04`). *Ears:* `SFX_SEED_TICK` in silence, then `CUE-05` returning and handing over to `CUE-02` for the October montage.

---

## 6. Chapter 4 — *Into the Cold Trap* (`EX-M0401`–`EX-M0404`)

Chapter question: how do two people in a rover and two at home make one safe field decision? Mastery: safe route and reserve ≥ 30, no blackout, all three beacons; Golden adds all beacons placed before their blind corners.

### 6.1 `EX-M0401` — Make the Old Map Current

`EX-CH04-S01`..`S03` · Descendant rack and prediction notebook, rover bay and base handover screen, shared route preview · **P-07** route choice · **22 min** · Data Cards: `viper_slope_limit` (15° `[M]`), `diviner_cold_traps` (38 K: why the destination is so cold `[M]`), `bvad_2022_metabolic` (`A0.5` per shift for two home cadets `[C]`) · Outpost Status: base 08 entry `E14/20, A8/10, H6, C8, R18`; two daylight base shifts at DIM/O0 cost `E2` each and breathe `A0.5` (witness `E18, A7, H6, C8, R16.8`); the rover's 48-hour manifest is a separate bar with its own "home" marker at 30 of 100.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Twelve descendants with text trait tags: seven purple stems, five green; `EX-CH04-S01-L02` Amara: "Seven purple, five green in this sample. Not a promised ratio." | OBJ + DLG | Descendant rack (S01) | M |
| 2 | The saved May prediction, unchanged, beside a new observation panel. | LOG | Notebook (S01) | A |
| 3 | Two ledgers: two people at base, two on the rover's independent manifest; `EX-CH04-S02-L03` Amara: "Two at base, two in the rover. Each ledger counts its own people." | INS + DLG | Handover screen (S02) | A |
| 4 | `EX-CH04-S02-L02` Ferreira (Earth link): "Rafi leads the field team. Returning is part of the objective." | DLG | S02 | All |
| 5 | Base-only slope card: route A max 24°, route B max 12°, route C max 18° (08). | LOG | Base console (S03) | A |
| 6 | Rover-only headlight card: the near-field view of each route's first corner and surface. | LOG | Rover display (S03) | R, K |
| 7 | Route cards with energy: A 8 km, 35 each way; B ridge 12 km, 30 each way; C shadow 10 km, 40 each way; rover 100, mandatory return reserve 30; design limit 15° (08). | INS | Shared route preview (S03) | All |

**2 · Deduction.** Both constraints must hold at once: slope ≤ 15° **and** 100 − outbound − return ≥ 30. A: 100 − 70 = 30 passes the reserve but 24° fails the slope. C: 100 − 80 = 20 fails the reserve and 18° fails the slope. B: 100 − 60 = 40 ≥ 30 and 12° ≤ 15°. **Aha:** *"The short road looks fine on energy; it's the slope that kills it. The return is already in the battery."* **Wrong-but-reasonable:** route A is the best trap in the game: its reserve exactly meets the rule, so an energy-only player picks it; Amara's private slope card makes her poll `NO-GO [FR-05]: Route A slope 24° exceeds 15° rover limit` (23 §3.3), and the route table blocks it with the reason. "Charge four people at base and two again in the rover" (S02's first option) is flagged as double consumption. "Seven to five proves a ratio" (S01's first option) is rejected beyond the sample.

**3 · Decision and escalation (the NASA way).** Trade-study card with three route columns (energy out, energy back, reserve left, max slope, crew hours) and `[BLOCKED BY FLIGHT RULE FR-05]` tags; the rationale field must name *both* constraints (canon: "the player must explain both constraints before departure"). Go/No-Go across the split team: Amara (slope card), Rafi and Kai (headlight card), Mei (garden status sent). Rover prep is an ODF checklist (seal, scanner, closed carrier, provisions). Risk card: "Route A 24°", 4 × 5, HIGH (23 §7.2). **Escalation:** S01 honesty about the old prediction → S02 Rafi's caution formally becomes leadership → S03 the route decision with the hatch already closed behind them. **Set piece:** S02 splits the frame between two occupied rover seats and two voices at home; S03 ends on the ridge bending out of sight beyond the rover window as `CUE-06` "Beyond Home" begins; the rover is heard only through cabin and chassis. **Outcomes (mastery):** *success*: route B with both reasons recorded and reserve forecast 40 ≥ 30. *Partial*: B was committed after the flight rule blocked A or C (the rule did its job; the debrief shows which card would have caught it earlier). *Failure*: n/a; blocked routes cannot commit and the departure gate requires exactly two plus two.

**4 · Hints.** 08 P-07: H1 "A short road may be too steep." · H2 "Check both the return cost and slope." · H3 "Choose B, use dry 2, then tag 18 and 19." Prediction review (`NEW`): H1 "Does twelve plants prove a rule for every plant?" · H2 "Describe what grew in this sample." · H3 "Record: 'In this sample of twelve, seven purple and five green.' Keep the May prediction beside it." **Modes:** Family shows each route as a bar of 100 with outbound and return blocks removed and a line at 30 (no pre-sorting, no answer marked); Engineer shows VIPER's 15° `[M]` and labels route slopes `[G]` pending the LOLA pass (SCIENCE_AND_DATA §B3-8).

**5 · Playtime and feel.** 7 + 7 + 8 minutes. *Hands:* tag twelve stems by trait, pack the rover (seal check, scanner, carrier), drag name tags to the base and rover ledgers, lay three route cards on the table and remove energy blocks from each bar. *Ears:* garden fans, rover-bay echo, `SFX_HATCH_SEAL`, `SFX_ROVER_CABIN`, `CUE-06`.

### 6.2 `EX-M0402` — Measure Before Claiming

`EX-CH04-S04`..`S06` · Surveyed ridge and three beacon positions, cold-trap reference and sample stations, vault approach · **P-07** beacons and ice survey; **P-08** discovery · **22 min** · Data Cards: `lcross_water_2009` (5.6 ± 2.9 % water ice by mass at the LCROSS site `[M]`), `chandrayaan1_m3_ice` (exposed ice in only about 3.5 % of cold traps: ice is patchy `[M]`), `diviner_cold_traps`, `kaguya_shackleton_floor` · Outpost Status: the rover bar with its reserve line; the base side keeps its own ledger.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Per-corner link test: a beacon counts only when its next-hop test passes; `EX-CH04-S04-L03` Amara (local link): "Only if the link test says so." | INS + DLG | Ridge (S04) | R |
| 2 | Base slope card shows approved mounts; rover view shows the local mounting surface (one clear view with an unsuitable mount; one approved mount needing alignment). | LOG | S04 | A (base), K (rover) |
| 3 | `EX-CH04-S05-L01` Kai: "That bright patch is ice, right?" | DLG | Sample station (S05) | K |
| 4 | Scanner: dry reference 2; threshold = reference + 10 = 12; samples 2, 18, 19 (08). | INS | S05 | A reads, K holds the scanner |
| 5 | A repeated reading from the same contact position agrees. | INS | S05 | R |
| 6 | A manufactured corner beyond the survey marker; `EX-CH04-S06-L01` Mei (local link): "That shape did not grow there." | OBJ + DLG | Vault approach (S06) | K sees, M matches to the map |
| 7 | The old deposit date agrees with the earlier authorised route; return reserve checked before recovery (`EX-CH04-S06-L04`). | LOG + INS | S06 | M, A |

**2 · Deduction.** Placement is not communication; a bright image is not a measurement; two discoveries are two records. **Aha:** *"Keep the negative sample. It's what makes the two positives believable."* **Wrong-but-reasonable:** crossing a corner after mounting a beacon without testing it (S04's first option): the gate holds. "Every bright patch is water" (S05's first option): the dry reference and the low sample reject a visual-only claim. An uncalibrated positive is marked unverified (08). "Combine everything as a single treasure find" (S06's first option): the board asks for separate sample and case records.

**3 · Decision and escalation (the NASA way).** Each corner is a mini Go/No-Go: Rafi's GO requires a passed next-hop test. The scanner follows the calibration ODF card from 23 §4.3 (`FR-06`: reference → threshold → samples → repeat one contact). The case triggers a handling assessment, not an action: separate photographs, a marker match, a return-reserve check (`FR-05`) and a tethered closed carrier. Risk card: "Link lost at a blind corner", 3 × 4, HIGH. **Escalation:** S04 navigation tension → S05 scientific temptation → S06 the discovery the chapter promised, with curiosity held by the return plan. **Set piece:** the headlight sweep in S06 finds a straight edge in a world of rock under a black sky, with hard black shadows and no drifting dust; `CUE-06` plays its 20-second sting; Kai's `EX-CH04-S06-L02` "Neither did we." lands over silence. **Outcomes (mastery):** *success / Golden*: three beacons linked before their corners, reference and threshold recorded, samples 18 and 19 tagged with 2 kept as the negative control, one sample sealed, case recorded separately, carrier tethered. *Partial*: a beacon's link was verified only after reaching its corner (star kept, Golden lost). *Failure*: off-road driving stops at a warning boundary and never tumbles into an unwinnable pit (08); an untested corner simply holds the gate.

**4 · Hints.** 08 P-07 hints as in 6.1. Beacons (`NEW`): H1 "Does a beacon talk, or just stand there?" · H2 "Test the next hop before driving past the corner." · H3 "Mount on the approved pad → align → link test PASS → then continue." **Modes:** Family can switch any driving segment to guided cruise or the station view; Engineer shows LCROSS 5.6 % `[M]` beside the scanner's counts `[G]`.

**5 · Playtime and feel.** 7 + 7 + 8 minutes. *Hands:* set a beacon on its mount, turn its alignment knob, press link test; touch the scanner to the reference, then each sample; tag; seal the sample cup; photograph case and marker; clip the carrier tether. *Ears:* `SFX_ROVER_CHASSIS` through the seat, `SFX_SUIT_BREATH`, `SFX_SCANNER_BEEP`, `SFX_RADIO_LOCAL_IN`, `CUE-06`.

### 6.3 `EX-M0403` — Recover Without Ruining

`EX-CH04-S07`..`S09` · Vault recovery work boundary, cradle and rover cargo mount, ridge return and Aurora airlock · **P-08** field sequence and return · **22 min** · Data Cards: `diviner_cold_traps` (38 K) and `kaguya_shackleton_floor` (below about 90 K): why a cold case meeting warm humid air condenses `[M]` · Outpost Status: rover reserve forecast versus actual; base ledger unchanged by the rover's occupants.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | External probe on the outer shell against the carrier handling band; `EX-CH04-S07-L04` Amara (local link): "Shell temperature is not a complete seed-history record." | INS + DLG | Work boundary (S07) | R probes, A interprets |
| 2 | Lettering visible beneath the lid; `EX-CH04-S07-L02` Mei (local link): "Then the lid can wait." | OBJ + DLG | S07 | K sees, M answers |
| 3 | Sleeve, cradle and mount, laid out in order; `EX-CH04-S07-L03` Rafi: "Probe, sleeve, cradle. Inner seal stays closed." | OBJ + DLG | S07 | R |
| 4 | The mount's latch shows closed; a separate lock test; `EX-CH04-S08-L02` Kai: "Mount shows closed. Testing locked now." | INS + DLG | Cargo mount (S08) | K |
| 5 | Cargo-and-return forecast with the two occupants still on their own manifest (`EX-CH04-S08-L04`). | INS | S08 | A |
| 6 | The beacon chain checked from the other direction on the way home. | INS | Ridge return (S09) | R |
| 7 | Amara's saved reserve prediction beside the actual final reading (`EX-CH04-S09-L03`). | INS | Airlock (S09) | A |

**2 · Deduction.** Keep it sealed until home; warm it sealed in a dry glovebox; an indication is not a verification; a forecast keeps its value beside the actual. **Aha:** *"The lid can wait."*: the strongest move is restraint. **Wrong-but-reasonable:** "a quick look would save work later" (Kai, S07): opening the biological seal in the field (S07's first option) is flagged for uncontrolled exposure and missing quarantine. "The latch looks closed" (S08's first option): the gate waits for the lock test. "Replace the prediction with the final reading" (S09's first option): the review rejects losing the comparison.

**3 · Decision and escalation (the NASA way).** The P-08 field ODF card (23 §4.3): Probe → Sleeve → Cradle → Mount, with `FR-06` interlocking any open command outside or before the dry warm-up. A two-person Go/No-Go before the lift (two support points; `EX-CH04-S08-L01`). Return is gated by the reserve (`FR-05`). Risk card: "Cold vault opened in cabin air", 3 × 4, HIGH (23 §7.2). **Escalation:** S07 the temptation at the lid → S08 the physical tension of the lift → S09 the long return and the first moment all four share a room again. **Set piece:** the lift shows the case moving continuously from its deposit to the cradle in the lit work area; in S09 `SFX_AIRLOCK_CYCLE` equalises, light shifts from rover-cabin blue to warm habitat white, and Mei rests her hand near the case without touching its lid. `CUE-06` resolves. **Outcomes:** *success*: sealed recovery, verified lock, reserve forecast ≥ 30 met on return, sealed case in dry quarantine. *Partial*: a forecast mismatch is recorded beside the prediction and investigated honestly. *Failure*: an open command is blocked with the condensation explanation; a damaged-outer-case false alarm never destroys specimens (08).

**4 · Hints.** 08 P-08: H1 "Keep it sealed until home." · H2 "Warm dry seeds in their closed container." · H3 "Complete sleeve/cradle, then three warm-up stages in the glovebox before opening." **Modes:** Family lifts by selecting both support points and confirming; Engineer shows the 38 K Diviner value `[M]` and labels the handling band `[G]`.

**5 · Playtime and feel.** 7 + 7 + 8 minutes. *Hands:* touch the probe to the shell, slide the sleeve on, two-point lift, latch and pull-test the mount, check each beacon on the way back, run the airlock panel, dock the case to the glovebox. *Ears:* suit breathing, `SFX_ROVER_CABIN`, latch clicks, `SFX_AIRLOCK_CYCLE`, `CUE-06` resolving.

### 6.4 `EX-M0404` — Bring the Question Home

`EX-CH04-S10`..`S12` · Dry quarantine glovebox, glovebox scan station and Earth console, mission table and prepared locker · **P-08** warm-up, opening and inventory; the inscription; Ferreira's relief flight · **24 min** · Data Cards: `change4_cotton` (Kai recognises cotton from the 2019 record), `diviner_cold_traps` · Outpost Status: Food gains a separate vault inventory (12) beside the founder reserve (30) and the descendants.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Glovebox warm-up stages cold → cool → room; condensation check `NONE` (08); `EX-CH04-S10-L01` Amara: "Stable and dry. Now we open it inside the glovebox." | INS + DLG | Glovebox (S10) | A |
| 2 | Twelve specimen wells with labels, matched to the vault ledger; `EX-CH04-S10-L02` Rafi: "Twelve distinct specimens. Twelve condition entries." | OBJ + LOG | S10 | R |
| 3 | The collection album (cultivar entries are records) versus the physical vault count. | LOG | S10 | M |
| 4 | Cotton among the twelve; `EX-CH04-S10-L03` Kai: "Cotton. Like the first chapter of the real history." | OBJ + CARD | S10 | K |
| 5 | The lid inscription; `EX-CH04-S11-L01` Mei: "The lid says: ask Commander Ferreira about Expedition Zero." | LOG + DLG | Scan station (S11) | M |
| 6 | `EX-CH04-S11-L03` Rao (Earth link): "Manifest received. Your safety support is unchanged." | DLG | Earth console (S11) | All |
| 7 | The fifth mug, and Ferreira's relief assignment: departs Earth 8 December, arrives 12 December with the planned support flight. | OBJ + LOG | Mission table and locker (S12) | K (mug), A (manifest) |

**2 · Deduction.** Knowledge and stock live in different ledgers; the inscription supports a request, not a verdict; a person cannot be on Earth's console and on the Moon at the same time. **Aha:** *"The case was preserved on purpose, and the lid tells us who to ask."* **Wrong-but-reasonable:** "An album entry adds another physical seed" (S10's first option) is a category error the ledger rejects. "A final verdict about who was abandoned" (S11's first option) is not supported by the record. "Ferreira appears without transit while still commanding from Earth" (S12's first option) is rejected by the chronology review.

**3 · Decision and escalation (the NASA way).** The glovebox ODF card finishes P-08 (three confirmed warm-up stages → condensation check → open inner seal → twelve labels → scan lid), and quarantine status is set to *pending viability evaluation*, not "healthy" (08, 23 MP-07). The Earth message follows CAPCOM practice: exact evidence plus the reconciled manifest, receipt recorded, personal question left open; Rao keeps operational support separate from personal hesitation. The relief flight is a logistics check (dates, cargo, fifth-occupant handover). Risk card: "Condensation on dry seed", 3 × 4, HIGH, mitigated by the staged warm-up. **Escalation:** S10 the payoff of restraint → S11 the inscription turns the mystery personal and Ferreira's channel goes quiet → S12 anticipation carried by an object. **Set piece:** the lid opens inside the glovebox to twelve wells in soft light; the lid scan resolves into a line of handwriting. In S11 the Earth console holds a silence before Rao answers. S12's last image is the fifth mug waiting on the table (T9), with Kai able to name the route that brings its owner. **Outcomes:** *success*: twelve specimens recorded and retained, lid scanned, request sent with receipt, locker and fifth-occupant handover ready by 12 December. *Partial*: a wrong label was corrected (08). *Failure*: opening before the dry warm-up is blocked with the condensation explanation.

**4 · Hints.** 08 P-08 hints as in 6.3. Inscription (`NEW`): H1 "What does the lid ask for, and what doesn't it say?" · H2 "Send the exact words and the manifest; leave conclusions out." · H3 "Send the lid image and the reconciled manifest, and ask the way Mei does in `EX-CH04-S11-L04`." **Modes:** Family advances each warm-up stage after one confirm; Engineer labels the three stages `[G]` and shows the album and vault as two tables.

**5 · Playtime and feel.** 8 + 8 + 8 minutes. *Hands:* glovebox gloves, the stage dial, a wipe check for condensation, opening the inner seal, moving each specimen label into its ledger slot, scanning the lid, composing the message, placing the mug, preparing the locker. *Ears:* `SFX_GLOVE_PORT`, a soft scanner chirp, Earth-link latency and a silence, the mug set down on the table.

---

## 7. Chapter 5 — *Shooting Stars* (`EX-M0501`–`EX-M0504`)

Chapter question: how do you reach a true account of the past, and how do you tell an observation from an instrument artifact? Mastery: six correct flashes, no blackout, maintenance passed; Golden adds all eight flashes with no false report. At chapter completion the player chooses Dust Shield or Whipple bumper (10_GAMEPLAY_SYSTEMS).

### 7.1 `EX-M0501` — The Engineer Comes Home

`EX-CH05-S01`..`S03` · Landing camera and airlock, corridor and atmosphere panel, mission table · **P-09** · **20 min** · Data Cards: `change4_cotton` (a real lunar plant trial that ended at the seedling stage, the honest parallel to Expedition Zero), `bvad_2022_metabolic` (five crew: `A1.25` and `R1.5` per 7.2 h shift `[C]`) · Outpost Status: occupancy changes from four to five; every forecast must be recomputed.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Two landing-clear indicators that must agree; `EX-CH05-S01-L02` Ferreira: "Ferreira. Seal indication checked twice." | INS + DLG | Airlock (S01) | R |
| 2 | The occupancy forecast, four versus five; `EX-CH05-S01-L04` Amara: "We are revising the occupancy ledger." | INS + DLG | S01 | A |
| 3 | A replacement relay controller in a sealed crate; `EX-CH05-S02-L03` Rafi: "Controller serial matches the manifest." | OBJ + DLG | Corridor (S02) | R, K |
| 4 | Amara's months-old handwritten correction, still visible on the atmosphere panel, and the second gauge. | OBJ | Atmosphere panel (S02) | A |
| 5 | Four chronology cards under transparent weights: seedling chart 3 Apr; relay/power fault 4 Apr 12:00; evacuation order 12:10; all crew boarding 12:40 (08), plus a greenhouse service note describing a connector already degraded. | LOG | Mission table (S03) | M (chart), K (fault, service note), R (order, boarding) |
| 6 | A photograph of frozen trays: a consequence that cannot date the fault. | OBJ | S03 | M |
| 7 | The ascent manifest: highlighted signatures `FER` and `N.R.`, four departed and four boarded; `EX-CH05-S03-L03` Rafi: "Every name has a boarding mark." | LOG + DLG | S03 | R |

**2 · Deduction.** Order by timestamps, separate an earlier condition from the moment it failed, then let the roster settle the human question. **Aha:** *"The garden was left. The gardener was not."* (`EX-CH05-S03-L04`). **Wrong-but-reasonable:** a sad photograph invites "the gardener was abandoned"; the board highlights the contradicting boarding evidence (08). "The degraded connector is when it failed": Amara's `EX-CH05-S03-L02` "A condition is not the failure time." A tidy player keeps the old four-person forecast after arrival (S01's first option); the preview shows the omitted demand.

**3 · Decision and escalation (the NASA way).** The airlock opens only after two agreeing checks and Ferreira's read-back (`FR-01`); the five-person roster is a Go/No-Go before the entry handover commits. The chronology is an MER investigation with primary records (23 §7.3 step 2), and the conclusion card commits only when all four cards are placed and the boarding check is done (Obra Dinn set confirmation). The gardener's full name is never inferred from initials (08). Risk card: "Inner door opened on one indicator", 2 × 5, HIGH. **Escalation:** S01 relief and procedure → S02 a deliberately quiet watch that makes Amara (and the player) suspicious → S03 the truth on paper. **Set piece:** a small moving shape on the landing camera beside settled cargo (no billowing dust); the inner door opens only after the read-back; Ferreira takes the corridor watch instead of the chair. In S03 Rafi exhales before anyone speaks. **Outcomes:** *success*: five-person roster verified, spare stored once with its procedure local, chronology chart → fault → order → boarding with ALL FOUR RETURNED committed. *Partial*: the chronology was reordered after a contradiction was shown. *Failure*: none; no loss, all evidence stays available (08).

**4 · Hints.** 08 P-09: H1 "Use the timestamps." · H2 "Boarding happened after the retreat order." · H3 "All four signatures boarded; the garden, not a person, was left behind." Occupancy (`NEW`): H1 "Who is in the station now?" · H2 "Air and food follow the number of people." · H3 "Switch the forecast to five occupants and re-check air and food before committing." **Modes:** Family uses an accessible list instead of spatial cards; Engineer shows the timeline in minutes and the BVAD per-person rates.

**5 · Playtime and feel.** 6 + 7 + 7 minutes. *Hands:* compare two indicators, scan cargo seals, carry the fifth mug, read a serial plate, sign a gauge reading, slide four cards under weights, match signatures with a loupe. *Ears:* `SFX_AIRLOCK_CYCLE`, a quiet corridor, paper on the table, no music until the reveal later in the chapter.

### 7.2 `EX-M0502` — The Parts We Left Unsaid

`EX-CH05-S04`..`S06` · Archive images at the mission table, shared seating, records desk and spare locker · No 08 puzzle: interpretation, an accountable conversation and the spare's compatibility check (it prepares P-16) · **20 min** · Data Cards: `change4_cotton`, `fast_plants_lifecycle` · Outpost Status: steady; the Evidence Board and the spare-parts inventory are the working screens.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | The 2034 growth sheet: young seedlings, curled leaves, evacuation before flowering; `EX-CH05-S04-L03` Ferreira: "We left before reproduction." | LOG + DLG | Mission table (S04) | M |
| 2 | Alo's own record beside it: flower, Tara's pollen, mature pods, dry-down, forty-two seeds; the pressed petal. | LOG + OBJ | S04 | M, A |
| 3 | `EX-CH05-S05-L01` Ferreira: "I was the engineer who could not fix the radio." | DLG | Shared seating (S05) | All |
| 4 | The vault had been placed during an earlier survey (Ferreira's account, matching the CH03 map date). | LOG | S05 | R |
| 5 | The old relay diagram beside the new controller's service card: connector specification, isolation points, actual serial; `EX-CH05-S06-L01` Kai: "Matching shape is not matching specification." | OBJ + DLG | Records desk (S06) | K |
| 6 | The personal identity page held by Rao for consented release; `EX-CH05-S06-L03` Mei: "Our other question needs permission." | LOG + DLG | S06 | All |

**2 · Deduction.** Two timelines can both be true: the 2034 trial stopped before flowering and Alo finished a step it could not. A technical fit and a personal permission answer different questions. **Aha:** *"Two kinds of repair."* (`EX-CH05-S06-L04` gives Ferreira the words.) **Wrong-but-reasonable:** "those shapes were flowers" (S04's first option) is revised against the growth sheet. "The spare looks the same, so it fits": Kai refuses to call housings interchangeable from a picture and the player compares connector, rating, isolation and mounting. Installing the spare now is not offered: the present uplink is working and the controller stays packed.

**3 · Decision and escalation (the NASA way).** S04 commits an archive interpretation through the Evidence Board. S05 is the blame-free lessons-learned practice (23 §7.4) in human form: no forgiveness meter, both factual topics acknowledged, the disagreement kept visible. S06 is an ODF compatibility check (MP-04) whose output is a signed technical note clipped inside the crate; the replacement procedure is stored so it opens without an Earth connection. Risk card: "Incompatible spare installed in the field", 2 × 5, HIGH, mitigated months before the finale. **Escalation:** S04 doubt about the crew's own achievement → S05 the hardest conversation in the game → S06 two calm, careful products. **Set piece:** Ferreira sits where a commander would usually stand, hands resting away from the records; the camera stays low and the score falls silent. The petal lies beside the frozen-garden photograph, and Mei revises one caption. **Outcomes:** *success*: interpretation committed as "young unflowered seedlings only", both topics acknowledged, both specification comparisons complete, the spare unused, the procedure verified to open offline. *Partial*: the caption was first written as "an old garden" and revised. *Failure*: none; every path keeps safety information available (canon exit).

**4 · Hints (`NEW`).** Interpretation: H1 "Read the growth sheet beside the image." · H2 "Curled leaves on a seedling are not petals." · H3 "Caption: 'Young unflowered seedlings, 2034; trial stopped before flowering.'" Compatibility: H1 "What makes two parts the same part?" · H2 "Check connector and rating, then isolation and mounting." · H3 "Serial ✓ · connector ✓ · rating ✓ · isolation points ✓ · mounting ✓ → sign the note, keep the spare packed." **Modes:** the conversation is never timed in any mode; Engineer shows the connector table.

**5 · Playtime and feel.** 6 + 7 + 7 minutes. *Hands:* lay two image timelines side by side and revise a caption; choose Mei's first question from two; compare pinouts under a magnifier; clip the note inside the crate. *Ears:* fans, paper, a long silence after `EX-CH05-S05-L03`, the crate latch.

### 7.3 `EX-M0503` — A Moon That Keeps Records

`EX-CH05-S07`..`S09` · Impact-camera monitor, maintenance console and isolated garden spur, evidence table · **P-10** observation and maintenance · **25 min** · Data Cards: `meo_lunar_impact_flashes` (NASA's lunar impact monitoring confirms flashes across independent observations; 126 calibrated flashes in five years `[M]`), `vsat_relocatable_array`, `bvad_2022_metabolic` · Outpost Status: 08 entry `E14/20, A8/10, H6, C8, R18`; three observation/maintenance phases at COZY / DIM / O0; dust lowers solar income from 8 to 6 until cleaned; the micro-leak costs `A1` per unresolved phase (0.5 with flexible seals); five-person breathing `A1.25` per phase; witness `E16, A4.25, H6, C8, R13.5, Z0`.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Ten candidates on the monitor: eight genuine transients and two persistent detector artifacts (08). | INS | Impact monitor (S07) | R (frame log), A (a reason per event) |
| 2 | `EX-CH05-S07-L02` Amara: "Not like meteors crossing Earth's air." | DLG | S07 | A |
| 3 | `EX-CH05-S07-L03` Rafi: "Check the frame before and after." | DLG | S07 | R |
| 4 | The panel trend below its reference (dust: income 8 → 6). | INS | Maintenance console (S08) | K |
| 5 | A separate pressure trace: a small leak on an isolated branch. | INS | Garden spur (S08) | A |
| 6 | Expedition Zero's damage report: relay failure and degraded power hardware, no verified strike; `EX-CH05-S09-L01` Rafi: "Tonight's flashes do not date the old fault." | LOG + DLG | Evidence table (S09) | R |

**2 · Deduction.** Across neighbouring frames, a real flash appears briefly at a mapped surface location with a distinct onset; a detector fault stays at the same detector coordinate. Two symptoms need two causes and two measurements. A plausible mechanism is not case evidence. **Aha:** *"A real flash changes; a detector fault stays."* **Wrong-but-reasonable:** count the persistent bright point (S07's first option): neighbouring frames expose it. "Dust explains the pressure drop" (S08's first option): cleaning changes output but not the isolated leak. "An impact caused the 2034 relay failure" (S09): the player moves the claim to Unsupported and the correction stays in the debrief.

**3 · Decision and escalation (the NASA way).** MER artifact rejection (23 §7.3 step 2) with a reason chip on every accepted event. A trade study on maintenance timing: immediate maintenance restores income 8 and stops the extra `A1` (23: P-10, MP-01). Two ODF cards (safe panel cleaning; isolate, patch and pressure-test the spur from its safe side, never opening the living enclosure). A bounded report with an honest blank (MP-07). Risk cards: panel dust 4 × 2 MODERATE, hot pixels 3 × 2 MODERATE (23 §7.2). **Escalation:** S07 wonder at an instrument → S08 maintenance under a visible cost clock (each unresolved phase drains air) → S09 restraint, ending in a blank Ferreira smiles at. **Set piece:** a dark room lit by the monitor, small enlarged flashes on a dark plain, no trails anywhere; the list of supported events grows one reason at a time. Mei's `EX-CH05-S07-L04` ("A tiny flash can leave a mark.") plays over the sixth confirmation. **Outcomes (mastery):** *Golden*: all eight flashes, no false report, maintenance verified. *Success*: six verified flashes, both artifacts rejected, cleaning and patch each passing their own measurement. *Partial*: six reached after a corrected mistag, or maintenance done one phase late (the air cost shows in the forecast). *Failure*: none punishing; mistags can be corrected without reaction-speed scoring, and unrepaired faults stay visible in the next forecast (08).

**4 · Hints.** 08 P-10: H1 "Compare more than one frame." · H2 "A real flash changes; a detector fault stays." · H3 "Verify six transients, clean and patch or verify the protective upgrade, then match the signed manifest." Report (`NEW`): H1 "Does tonight's evidence say anything about 2034?" · H2 "A hazard that exists is not proof it caused this fault." · H3 "File 'impact caused the 2034 fault' under Unsupported; keep 'impacts are a monitored hazard'." **Modes:** review is untimed in every mode (08); Engineer shows the MEO method and counts `[M]` and labels the 8 → 6 dust loss `[G]`.

**5 · Playtime and feel.** 8 + 9 + 8 minutes. *Hands:* scrub frame by frame, tag a candidate and pick a reason chip, run the panel-cleaning procedure, isolate and patch the spur, pressure-test, drag claims to Supported or Unsupported. *Ears:* monitor hum, a soft confirm per event, `SFX_CLAMP_SEAT`, `SFX_PUMP_PRESSURE` for the test, quiet.

### 7.4 `EX-M0504` — Permission to Answer

`EX-CH05-S10`..`S12` · Mission table with live Earth data link, message composer, indoor reference bay · **P-10** identity match and invitation; cotton planting · **20 min** · Data Cards: `change4_cotton` · Outpost Status: Food shows three separate ledgers for the first time: vault (1 planted + 11 stored = 12), founder reserve 30, descendants.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | A signed page and a permission note; `EX-CH05-S10-L01` Rao (live Earth link): "She gave permission to share the page." | LOG + DLG | Mission table (S10) | All |
| 2 | The recovered manifest signature `N.R.` from P-09. | LOG | S10 | R |
| 3 | The delivery-receipt list: creation times against delivery after contact returned; `EX-CH05-S10-L04` Rao: "Every one that reached Earth." | INS + DLG | S10 | A |
| 4 | The anonymous packet image ("ALO", "N.") placed beside the signed page. | OBJ | S10 | M |
| 5 | `EX-CH05-S12-L01` Noor (text): "Thank you for asking. I would like to see what you grow next." | LOG | Message log (S12) | All |
| 6 | The quarantine record clearing one cotton specimen; `EX-CH05-S12-L02` Amara: "Cotton planted. Eleven other vault specimens protected." and `EX-CH05-S12-L03` Rafi: "Founder reserve is a separate ledger." | INS + DLG | Reference bay (S12) | A, R |

**2 · Deduction.** A signed, consented record (not a nationality, not an initial) establishes identity; Noor knew only what was delivered, and only after it was delivered; three inventories stay three. **Aha:** *"Noor saw what we sent, after we sent it, not everything we did."* **Wrong-but-reasonable:** "a Bangladeshi gardener with the initial N. must be Noor" is refused: the connection comes from the signed record, not nationality (08). Kai's `EX-CH05-S11-L01` "Should we send every graph?": Amara moves them to attachments. "Sixteen minus one equals fifteen stored" (S12's second option) counts album entries and is rejected.

**3 · Decision and escalation (the NASA way).** Identity follows a consent gate (23 P-10, `FR-06` consent): match the signature, check receipts, then and only then expand N.R. in the Journal. The invitation is sent once with its receipt kept (MP-08 communication states). Cotton planting repeats the P-01 checklist gesture (label, medium, pressure-safe bay). Inventory reconciliation closes with two separate signatures. **Escalation:** S10 the reveal → S11 vulnerability (writing to someone) → S12 a reply in text and a new seed. **Set piece:** `CUE-07` "A Name" rises as the journal expands the initials into Dr. Noor Rahman's full name, only after the shared reveal; S11 keeps the camera on Mei's hands over the composer; S12 frames the cotton cassette exactly like Alo's first planting. **Outcomes (mastery):** *success*: identity matched with consented evidence, invitation delivered once, cotton planted 15 December, vault 1 + 11 and founder 30 reconciled; the upgrade choice follows. *Partial*: a ledger mismatch was corrected before closing. *Failure*: none; the first live Noor voice stays reserved for Chapter 8 in every path.

**4 · Hints.** Identity uses 08 P-10 H3's last clause ("then match the signed manifest"). Inventories (`NEW`): H1 "Which items are seeds, and which are pages?" · H2 "The vault is twelve real specimens; the founders are a different box." · H3 "Vault: 1 planted + 11 stored = 12. Founder reserve: 30, untouched. Album entries: not seeds." **Modes:** Family composes by choosing one of the two authored openings (all modes do; nothing is typed freely); Engineer shows the receipt timestamps.

**5 · Playtime and feel.** 6 + 7 + 7 minutes. *Hands:* overlay two signatures, scroll the receipt list, choose the invitation's first line, attach a photograph and the checked report, plant cotton through the glove port, sign two ledgers. *Ears:* `SFX_RADIO_EARTH_IN`, `CUE-07`, a quiet send tone with no reply, `SFX_GLOVE_PORT`.

---

## 8. Chapter 6 — *The Red Ring* (`EX-M0601`–`EX-M0604`)

Chapter question: how do you plan for a human need (Kai's fear of the dark) inside a finite energy budget, and recover from a bounded fault? Mastery: five acknowledged segments, no blackout, live garden; Golden adds `E ≥ 2` at recovery (P-11's accepted plan ends at `E7`).

### 8.1 `EX-M0601` — A Plan for Darkness

`EX-CH06-S01`..`S03` · Power room and hand-light locker, dated personal log, eclipse allocation board · **P-11** · **20 min** · Data Cards: `nasa_eclipse_2047_01_12` (catalog 09755: total 70.0 min; contacts U1 23:40, U2 00:50, U3 02:00, U4 03:09 UT `[M]`), `jpl_horizons_pole_season` (Sun +0.14° at the pole on 12 January 2047 `[C]`) · Outpost Status: the 14-unit jar with a locked `7 E RECOVERY RESERVE` bracket (23 `FR-04`); 08's disclosed fallback allocation of seven units.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | The scratched hand light from the first night; its battery needs a measured charge; `EX-CH06-S01-L01` Kai: "The lamp still matters." | OBJ + DLG | Locker (S01) | K |
| 2 | Kai's short memory log (audio with a text equivalent; skippable); `EX-CH06-S02-L01` Kai: "I did not know when it would return." | LOG | Power room (S02) | K |
| 3 | The protected package: air circulation, minimum heat, dim growth light, guide light; `EX-CH06-S01-L04` Amara: "Guide light goes on the protected list." | INS + DLG | Allocation board | A |
| 4 | The guide-light branch drawn on every segment card (Rafi points to it). | INS | S02 | R |
| 5 | Five segment cards: precharge, ingress, totality, egress, recovery; essentials 1 per segment; pump readiness 1 once, before its deadline in segment 1; camera readiness 1 once, before segment 2; decorative floods 3 per activation (08). | INS | Allocation board (S03) | All; pump deadline M, camera deadline R |
| 6 | `EX-CH06-S03-L03` Rafi: "Seven game units, one accounting model." | DLG | S03 | R |

**2 · Deduction.** Five essential packages plus one pump and one camera preparation equal seven, which fits the protected seven-unit allocation and leaves the recovery reserve whole; floods would cost three each without adding an essential service. **Aha:** *"What Kai needs is a known way through the dark, not a bright room."* **Wrong-but-reasonable:** "Four essentials plus decorative floods" (S03's second option) leaves one segment unprotected and spends margin. "Switch everything off in totality to save power": the missing package names the exact service warning in that segment (08). "Add an elapsed-time bill on top": the board refuses a second accounting model (canon: "it does not add a second elapsed-time bill").

**3 · Decision and escalation (the NASA way).** Trade-study card "Which allocation protects every required eclipse segment?" (7 units for the eclipse versus 7 kept for recovery; floods compared and rejected); `FR-04` blocks any allocation over seven; the Go/No-Go runs across all five segments (23: P-11); the human-factors need (guide light, chosen companion) is written into the plan as a load, not a weakness. Risk card: "Unprotected segment", 3 × 4, HIGH. **Escalation:** S01 an admission ("still afraid of the dark") → S02 a memory turned into checkable questions → S03 the seven-unit promise. **Set piece:** the room keeps its ordinary hum while the checklist fills; Kai clips the charged lamp where both hands stay free; the jar shows its locked recovery bracket. **Outcomes (mastery):** *success*: essentials `[1,1,1,1,1]`, pump and camera each once before their deadlines, floods OFF, total 7 (08's accepted plan or an equivalent placement). *Partial*: the plan passed after an overspend warning was corrected. *Failure*: committing more than seven is blocked with the reserve warning; editing is free before commit (08).

**4 · Hints.** 08 P-11: H1 "Protect essential services throughout." · H2 "Five essentials plus one pump and one camera equal seven." · H3 "Keep essentials ON, prepare pump in 1 and camera in 2, with floodlights OFF." **Modes:** untimed in all modes; Family shows each package as one token; Engineer shows the catalog's contact times `[M]` and labels the seven-unit allocation as 08's disclosed fallback `[G]` (SCIENCE_AND_DATA §B3-10).

**5 · Playtime and feel.** 6 + 7 + 7 minutes. *Hands:* turn the charge dial on the hand light and clip it on, choose the companion, drag service packages onto five segment cards, expand a package to see its parts. *Ears:* power-room hum (`SFX_FAN_NORMAL`), Kai's optional memory audio with captions, the clip of the lamp.

### 8.2 `EX-M0602` — The Plan We Share

`EX-CH06-S04`..`S06` · Power room side-by-side preview, protected-bus test panel, mission table and filtered camera · **P-11** commit; **P-12** rehearsal · **25 min** · Data Cards: `nasa_eclipse_2047_01_12` · Outpost Status: matched previews spend nothing; the test branch is shown apart from the protected bus.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Two matched previews, decorative floods versus guide light, same forecast and equipment; `EX-CH06-S04-L02` Rafi: "You need a known way through it." | INS + DLG | Power room (S04) | K |
| 2 | The rehearsal test branch, labelled with text as well as colour; `EX-CH06-S05-L01` Amara: "Predict the affected branch first." | INS + DLG | Test panel (S05) | A |
| 3 | The same route read physically across the panel. | OBJ | S05 | K |
| 4 | The local checkback; `EX-CH06-S05-L03` Rafi: "Local channel check. Here." | INS + DLG | S05 | R |
| 5 | Three role reports collected by Kai: `EX-CH06-S06-L01` Mei "Plants checked.", `L02` Amara "Atmosphere checked.", `L03` Rafi "Shelter, lamp and local channel checked." | DLG | Mission table (S06) | M, A, R (each privately first) |
| 6 | The external camera's protective filter configuration, checked before any image appears. | INS | Filtered camera (S06) | R |

**2 · Deduction.** A matched comparison isolates one changed load; an isolation boundary limits what a fault can reach; "ready" is the sum of acknowledged reports, not one confident voice. **Aha:** *"Ready means all of us."* (`EX-CH06-S06-L04`). **Wrong-but-reasonable:** "keep the floods on so the corridor never feels dark" (Kai's own proposal, S04): the matched preview shows the margin spent with no essential service gained, and the guide light meets the need. Expecting the test disconnect to black out the habitat (S05): the board traces the isolating edge instead of saying "wrong". Pressing one unlabelled confirm repeatedly (S06): the readiness tokens need each labelled acknowledgement.

**3 · Decision and escalation (the NASA way).** S04 commits P-11 from the trade-study card with Kai's chosen compromise described to Mei (a dissent resolved, 23 §1.2). S05 rehearses the P-12 ODF card on a safe test branch (Portal), with `FR-04`'s protected bus untouched; Ferreira separates rehearsal from readiness (`EX-CH06-S05-L04`: "A rehearsal pass does not sign the watch."). S06 is the chapter's literal Go/No-Go poll: four role reports, five segments, the camera configuration. Risk card: "Feeder F2 trip", 3 × 3, MODERATE (23 §7.2). **Escalation:** S04 a personal compromise → S05 a rehearsal of the failure that is coming → S06 the ritual before the event. **Set piece:** Ferreira asks whose call it is; Kai looks around the occupied work positions before answering; the room dims to the planned eclipse lighting and only the guide-light path stays bright. **Outcomes:** *success*: floods shed with both plans kept in the debrief, test branch restored and recorded separately, four role checks and five segments acknowledged, camera filter verified. *Partial*: a missing report was caught by the readiness board and collected. *Failure*: none; the rehearsal ends in the same safe state it began.

**4 · Hints.** S04 (`NEW`): H1 "What does the extra brightness buy?" · H2 "Compare the two plans with one load changed." · H3 "Shed decorative floods; keep the guide-light branch on every segment." S05 (08 P-12): H1 "Keep the protected bus untouched." · H2 "Isolate the failed feeder before reset." S06 (`NEW`): H1 "Whose observations does the schedule depend on?" · H2 "Collect each role's report and repeat back what the plan needs." · H3 "Plants → atmosphere → shelter, lamp and channel → five segments → camera filter." **Modes:** Class mode makes S06 a real round-table: each group reads its own report aloud; Engineer shows the branch currents.

**5 · Playtime and feel.** 8 + 9 + 8 minutes. *Hands:* toggle one load in matched previews, tap the branch you predict, throw the safe test disconnect and restore it, walk to each station to collect its token. *Ears:* hum, `SFX_BREAKER_RESET` on the test branch, local-channel clicks, the quiet of dimmed lights.

### 8.3 `EX-M0603` — All the Sunrises

`EX-CH06-S07`..`S09` · Filtered remote-camera monitor, Earth family audio link, message log and eclipse desk · **P-12** ingress and ring records; family call; Noor's text · **20 min** · Data Cards: `nasa_eclipse_2047_01_12` · Outpost Status: steady under the committed P-11 plan; an Earth-path indicator shows the scenario-valid window.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | The filtered camera image: a dark disc taking a growing bite, then a red rim; `EX-CH06-S07-L01` Mei: "Every sunrise and sunset at once." | INS + DLG | Camera monitor (S07) | M |
| 2 | Two labels: the verified eclipse calendar date (catalog) and Aurora's viewing geometry (still unverified). | CARD | S07 | A |
| 3 | A conceptual Earth cross-section showing sunlight passing through the atmosphere at Earth's edge; `EX-CH06-S07-L02` Amara: "A picture for light passing through Earth's air." | OBJ + DLG | S07 | A |
| 4 | The communication-path check for the authored window; `EX-CH06-S08-L01` Family (Earth audio): "Is someone there with you?" | INS + DLG | Earth audio link (S08) | K, All |
| 5 | `EX-CH06-S09-L01` Noor (text): "I watched a red ring from there once. — N." | LOG | Message log (S09) | All |
| 6 | The evidence field for Noor's earlier eclipse date, left unspecified; `EX-CH06-S09-L03` Amara: "The earlier date stays unspecified." | INS + DLG | Eclipse desk (S09) | A |

**2 · Deduction.** Separate three kinds of statement: sourced astronomy (the catalog date and contacts), a diagram (why the rim is red), and fictional local timing. Communication depends on a path, not on how much the moment matters. A sincere memory is not a measurement. **Aha:** *"The red is sunlight bent through Earth's air: every sunrise and sunset at once."* **Wrong-but-reasonable:** "a geographically resolved Bangladesh sunrise stripe" (S07's first option): the conceptual inset cannot support it. "The eclipse opens the radio": the call connects only after the path check. "Add the exact date of Noor's eclipse": Amara leaves the field empty, because inventing it would look scientific and be less true.

**3 · Decision and escalation (the NASA way).** Evidence chips (23 §1.3: OBSERVED / COMPUTED / SIMULATED) on every saved record; the call follows MP-08 (path check → connect → buffer if interrupted → receipt); records are saved locally before anything else can go wrong (Rafi, `EX-CH06-S09-L04`). The decisions are what goes home with the greeting and how Noor's note is indexed; both options are valid and carry their labels. **Escalation:** S07 the chapter's wonder peak → S08 family, the emotional peak → S09 a calm save that matters in the next scene. **Set piece:** `CUE-08` "Red Ring"; the room goes quiet without taking the controls away; the player can hold the frame on the rim and open the diagram. No one looks at the Sun or outside: it is a protected instrument view. **Outcomes:** *success*: ingress and ring logged with their evidence labels, contact delivered or buffered through the valid path, Noor's text stored as known correspondence, camera state saved. *Partial*: a label was corrected (the stripe claim moved out). *Failure*: none; an interrupted call keeps its buffered words.

**4 · Hints (`NEW`).** H1 "Which parts of this picture were measured, and which are a drawing?" · H2 "The catalog gives the date and times; the diagram explains the colour." · H3 "Log: 'Ingress and ring [OBSERVED, filtered camera]; red rim explained by Earth's atmosphere [DIAGRAM]; local timing [SCENARIO].'" **Modes:** Engineer shows the catalog's U1–U4 times and the 70.0-minute totality `[M]`.

**5 · Playtime and feel.** 6 + 7 + 7 minutes. *Hands:* mark ingress on the timeline, hold the ring frame, open the cross-section, run the path check, connect the call, choose one observation packet, pin Noor's note. *Ears:* `CUE-08`, the family's voices with Earth-link latency, Rafi's "Hello from the lamp department." (`EX-CH06-S08-L03`), the soft click of a local save.

### 8.4 `EX-M0604` — The Light That Returns

`EX-CH06-S10`..`S12` · Power room and camera feeder F2, restored camera and debrief board, monitoring calendar and garden · **P-12** fault, egress and recovery; monitoring handover · **20 min** · Data Cards: `nasa_eclipse_2047_01_12` · Outpost Status: protected services hold while only the camera branch drops; recovery reconciles to `E7`.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | The view screen drops; the guide light stays on. | INS + OBJ | Power room (S10) | K |
| 2 | Protected-service indicators stable; `EX-CH06-S10-L03` Amara: "Essentials hold. Isolate F2." | INS + DLG | S10 | A |
| 3 | F2 current reads 0 and the indicator reads `FAULT CLEARED` after isolation (08). | INS | Feeder F2 (S10) | K |
| 4 | `EX-CH06-S10-L01` Kai: "Rafi, stay on the channel." / `L02` Rafi: "Here." | DLG | S10 | R |
| 5 | The egress time label beside the saved ingress and ring frames; the recovery reserve to reconcile. | INS | Debrief board (S11) | M (records), A (reserve) |
| 6 | The next morning's solar image with an active region; `EX-CH06-S12-L02` Amara: "Watching is not an exact storm forecast." | INS + DLG | Monitoring calendar (S12) | R |

**2 · Deduction.** A bounded fault deserves a bounded response: isolate F2, confirm zero and fault cleared, reset, reconnect, test the camera branch only. **Aha:** *"The guide light stayed on: the plan worked before I fixed anything."* **Wrong-but-reasonable:** "reset all habitat power" (S10's first option): the preview names the unnecessary disruption. Resetting before isolating is interlocked and explained in words (08). In S12, drawing a line from the active region straight to a February storm date is stopped: a region is a reason to watch, not a month-ahead prediction.

**3 · Decision and escalation (the NASA way).** The exact ODF card in 23 §4.3 (Do NOT trip the protected main bus; isolate before reset; ✓ verify after each step), `FR-04`, closed-loop checkback with Rafi, and the MER sequence "stop, identify, isolate, verify". The recovery reconcile charges no hidden fault penalty. S12's handover names instruments, observations and who checks the next report. Risk card: "Feeder F2 trip", 3 × 3, MODERATE. **Escalation:** S10 the interruption Kai feared → S11 egress recorded with the interruption kept in the record → S12 the long, calm watch. **Set piece:** the screen goes dark, the guide light stays, Kai's hand tightens on the lamp, then he speaks each action as it happens; `SFX_BREAKER_RESET`, and the camera image returns before the last observation gate. In S12 the cotton has leaves and the petal stays in the archive. **Outcomes (mastery):** *Golden*: F2 restored in sequence and the reserve reconciles at `E ≥ 2` (the accepted plan gives `E7`). *Success*: egress recorded, interruption and recovery both documented, monitoring ownership set, reserves confirmed. *Partial*: a reset attempted before isolation was interlocked and corrected. *Failure*: none lethal; retry from the feeder-trip checkpoint (08).

**4 · Hints.** 08 P-12: H1 "Keep the protected bus untouched." · H2 "Isolate the failed feeder before reset." · H3 "F2 off, confirm 0, reset, reconnect, camera test." Watch handover (`NEW`): H1 "What does an active region tell you, and what doesn't it?" · H2 "Give every instrument a named watcher." · H3 "Pin the region, assign who checks each report, and set no storm date." **Modes:** Family untimed; Cadet may enable 08's optional 90-second pressure with pause; Engineer shows the branch currents and contact times.

**5 · Playtime and feel.** 6 + 7 + 7 minutes. *Hands:* open the F2 isolation switch, read the meter, throw the breaker reset, close the isolation, press camera test, clip the lamp back, pin the monitoring calendar. *Ears:* the dropped screen's silence, Rafi's "Here.", `SFX_BREAKER_RESET`, the camera's return, `CUE-08`'s tail.

---

## 9. Chapter 7 — *The Great Storm* (`EX-M0701`–`EX-M0704`)

Chapter question: can four specialists and a commander turn four good ideas into one plan that protects five people, the living crops and the founder seeds? Mastery: `Z ≤ 6`, no blackout, living crops and protected seeds; Golden adds no unsafe committed response.

### 9.1 `EX-M0701` — Your Call, Cadets

`EX-CH07-S01`..`S03` · Mission table, life-support board and shelter roster, integrated storm planning table · **P-13** · **25 min** · Data Cards: `donki_2012_07` (CME 3,435 km/s aimed at STEREO-A, not Earth `[M]`), `stereo_a_het_2012_07` (the real proton curve), `crater_dose_2012_07` (the Moon did see particles: 0.57 → 3.92 mGy/day `[M]`), `clowdsley_2021_shielding` (`S6` = 20 g/cm² `[C]`), `bvad_2022_metabolic` · Outpost Status: 08's Chapter 7 snapshot `E30/32, A10/10, H6, C8, R18`, six shared water units, two crate-shield units, the two-compartment seed case; six dark 7.2 h steps with multipliers `[1,1,2,2,1,1]` and no solar income.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | The warning with its source label: a July 2012 event observed at STEREO-A; the Moon strike in 2047 is a counterfactual scenario. | INS + CARD | Mission table (S01) | R |
| 2 | `EX-CH07-S01-L02` Rao (live Earth link): "Historical source received and labelled." and `L03` Ferreira: "Your plan, cadets. I retain command responsibility." | DLG | S01 | All |
| 3 | The old first-night card listing four crew; `EX-CH07-S02-L01` Amara: "April's card counted four." | OBJ + DLG | Life-support board (S02) | A |
| 4 | Five-person rates: `A1.25` and `R1.5` per step (08); `EX-CH07-S02-L03` Mei: "Plants are not our whole life-support system." | INS + DLG | S02 | A, M |
| 5 | The shelter diagram with five seat markers. | OBJ | Shelter roster (S02) | R |
| 6 | Four private proposals: Kai's power margin (`E30/32`, costs per step, no income), Amara's uninterrupted circulation, Mei's warm roots and the garden's water, Rafi's full shielding `S = min(6, W + K)`. | LOG | Planning table (S03) | K, A, M, R |
| 7 | The multiplier chart `[1,1,2,2,1,1]` beside the real STEREO-A curve; the uplink-isolation task due before the peak. | INS + CARD | S03 | R (chart), K (isolation) |

**2 · Deduction.** Overlay the four plans and find the collision: water borrowed for the shelter is water the garden cannot use until it returns. Two preparation transfers put `W4` in the wall; with `K2` bundles, `S = 6` gives zero game dose even in peak steps; the drain to `W2` happens in step 6 *after* that step's exposure (08). **Aha:** *"Water and cargo share the shielding job, so the garden only has to lend four, not six."* **Wrong-but-reasonable:** "a measured 2012 storm hit Aurora in 2047" (S01's first option) is flagged as a source and date mismatch. "Reuse the four-person profile" (S02's first option) omits Ferreira. "Fill all six units into the wall for maximum safety": shelter is already capped at 6 with `K2`, so the extra two units buy no protection and leave the garden reservoir empty (garden water = 6 − `W`, 08). "Drain shielding water before a later exposure" (S03's first option) shows reduced protection at the next sample.

**3 · Decision and escalation (the NASA way).** The six-step plan is one trade-study card with every role's dependency traced through the same steps and a dissent field that must read "nobody's objective was left outside" (Ferreira's question, S03). `FR-01`..`FR-04` and `FR-06` (both 15-seed compartments latched before the peak; uplink isolation scheduled) are badged. A five-person Go/No-Go with the cadets polling and Ferreira holding command responsibility. ALARA is explicit (23 §6.2: Clowdsley's real curve beside the game table). Risk card: "Unshielded peak step", 5 × 5, HIGH. **Escalation:** S01 a shared warning delivered without a joke → S02 the boundary conditions changed (five people) → S03 four good intentions collide and become one plan. **Set piece:** breakfast stops; bowls stay on the table; Ferreira moves her chair away from the head of the table (T8, T9); `CUE-09` "All We Learned" begins its first stem. **Outcomes (mastery):** *success / Golden path*: the feasible plan W `[4,4,4,4,4,2]`, `K2` throughout, COZY / DIM / O0 in all six steps, founder 30 latched, five-person roster acknowledged, uplink isolation scheduled; 08 forecasts `E6, A2.5, H1, C3, R9, Z0`. *Partial*: an alternative plan that meets the same safety and living-garden goals (08 accepts it) with a worse forecast (`Z > 0` or a thinner margin). *Failure*: an infeasible plan stays in preview as `NO-GO`; there is no irreversible cost during preview (08).

**4 · Hints.** 08 P-13: H1 "Put the seeds inside before the peak." · H2 "Water and cargo share the shielding job." · H3 "Prepare W4 and K2; COZY/DIM throughout; drain in step 6 after exposure." Guided plan available. **Modes:** Family has the Guided plan; Engineer shows the STEREO-A fluence per step against the game multipliers and the pending proposal (SCIENCE_AND_DATA §B3-11) without changing them.

**5 · Playtime and feel.** 8 + 8 + 9 minutes. *Hands:* open the source-label tab before the forecast, move four then five seat markers, lay four transparent plan sheets over each other on the table and pull the conflicts into one schedule. *Ears:* breakfast clink stopping, `SFX_ALERT_PARTICLE` as an instrument tone, Rao's latency, `CUE-09`.

### 9.2 `EX-M0702` — What Gets the Last Drop

`EX-CH07-S04`..`S06` · Shelter water wall and seed case, Safe Room, Safe Room local telemetry · **P-13** preparation executed; **P-14** steps 1–2 · **25 min** · Data Cards: `clowdsley_2021_shielding`, `bvad_2022_metabolic`, `stereo_a_het_2012_07` · Outpost Status: the first committed steps change the ledger exactly as previewed; `Z ≤ 6` is badged.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | The seed case: two compartments of fifteen; seals against the thirty-seed record; `EX-CH07-S04-L01` Mei: "Fifteen and fifteen. Thirty founders." | OBJ + DLG | Seed case (S04) | M |
| 2 | The physical valve diagram with two return times; `EX-CH07-S04-L03` Amara: "Return after the sample, not before." | INS + DLG | Water wall (S04) | A |
| 3 | Supply bundles secured; `EX-CH07-S04-L02` Rafi: "Bundles stay through the last exposure." | OBJ + DLG | S04 | R |
| 4 | The roster: a seat icon, a name, a position and an answer must all agree (S05). | INS | Safe Room (S05) | R |
| 5 | Two hatch indications to compare; the protected branch and the scheduled isolation of exposed radio hardware (`EX-CH07-S05-L02`). | INS | S05 | R (hatch), K (branch) |
| 6 | Steps 1–2 actual values against the forecast; the garden's local telemetry; one seed compartment's sensor value (`EX-CH07-S06-L03`). | INS | Local telemetry (S06) | A, M |

**2 · Deduction.** Sequence: sample the exposure, then drain. People are verified by more than one channel. A sealed case is checked through its telemetry, never by opening it during exposure. **Aha:** *"The water doesn't disappear; it changes job."* (canon learning: "Resources retain quantity while their location changes their function."). **Wrong-but-reasonable:** "drain, then sample" (S04's first option) removes protection before it is needed. "Advance because the seat icon is green" (S05's first option): the gate names the missing human confirmation. "Open the seed case to inspect it" (S06's first option): the interlock explains why sealed telemetry is the safe check.

**3 · Decision and escalation (the NASA way).** Ferreira's rule, `EX-CH07-S04-L04` "Name the valve, then touch it.", is the ODF habit made audible. The five-person roll call is the Go/No-Go (`EX-CH07-S05-L01`..`L04`), `FR-03` locks the hatch, `FR-06` keeps the case latched. Each committed step is followed by a forecast-versus-actual comparison (MP-07: test the plan rather than replace observation). Risk card: "Hatch open during exposure", 2 × 5, HIGH, interlocked. **Escalation:** S04 the last preparations, where every drop has a destination → S05 everyone inside and the hatch sealed → S06 the first wave, checked rather than merely endured. **Set piece:** `SFX_HATCH_SEAL`, two indications agreeing, then the first committed step; Safe Room task lighting, restrained room sound, no glowing radiation anywhere; Mei touches the case once and closes it. **Outcomes:** *success*: founder 30 latched, return order verified, five occupants confirmed, both hatch indications agree, steps 1–2 match the forecast. *Partial*: a hatch mismatch held the step clock until the check was repeated. *Failure*: an unsafe committed dose or air state offers a pre-step retry (08).

**4 · Hints.** 08 P-13 hints (preparation) and P-14: H1 "Finish all three waves before going outside." Roster (`NEW`): H1 "Is a green chair the same as a person answering?" · H2 "Name, position and answer must agree." · H3 "Call each name, hear each answer, confirm each seat, then commit." **Modes:** Family has the Guided plan; Engineer shows dose per step from the shelter table times the multiplier (game units, not mSv).

**5 · Playtime and feel.** 8 + 9 + 8 minutes. *Hands:* carry the case two-handed and latch both compartments, point at the valve before turning it, tap the roll call, pull the hatch lever, commit steps one and two. *Ears:* `SFX_WATER_TRANSFER`, `SFX_HATCH_SEAL`, local-channel answers in five voices, `CUE-09`'s first stem.

### 9.3 `EX-M0703` — What We Carry

`EX-CH07-S07`..`S09` · Safe Room archive player and forecast table, integrated control panel, local network and uplink diagnostic · **P-14** steps 3–6, the last log, the uplink diagnosis and route readings · **30 min** · Data Cards: `stereo_a_het_2012_07`, `change4_lnd_surface_dose` (quiet-Sun lunar surface dose 13.2 ± 1 µGy/h `[M]`), `clowdsley_2021_shielding` · Outpost Status: the peak in steps 3–4 with the shield bar holding at 6; 08's witness ends `E6, A2.5, H1, C3, R9, Z0, W2, K2`, reserve 30 safe.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Noor's historical recording, stored locally: `EX-CH07-S07-L01` "I'm calling the seeds Alo, light." | LOG | Archive player (S07) | All |
| 2 | The first seed packet, the consented identity page and the founder ledger, laid side by side. | OBJ + LOG | Forecast table (S07) | M |
| 3 | The peak on the chart and the effective shield `S6`; `EX-CH07-S08-L01` Rafi: "Peak on the chart. Check the shield." | INS + DLG | Control panel (S08) | R |
| 4 | `EX-CH07-S08-L02` Kai: "No new solar income." and `L03` Amara: "Five-person draw still applies." | DLG | S08 | K, A |
| 5 | Three branch tests: local network PASS, direct dish path FAIL, external feedthrough FAIL (08); `EX-CH07-S09-L01` Kai: "I can hear Rafi. Earth cannot hear us." | INS + DLG | Uplink diagnostic (S09) | A (tests), K (local radio) |
| 6 | Route dosimeter: 0.4, then 0.3 ten scenario minutes later; a 1.2 reading does not clear; threshold 1 (08). | INS | S09 | R |

**2 · Deduction.** Judge safety by the shield, not by the frightening shape of the graph; diagnose by contrast: a test that *passes* matters as much as one that fails; one reassuring reading is not enough. **Aha:** *"I can hear Rafi and the garden is still talking, so the failure is on the path out to Earth."* **Wrong-but-reasonable:** "We have already survived every wave" (S07's first option) is contradicted by the four remaining steps. "Remove cargo to make room at the console" (S08's first option): the shield forecast shows the lost protection. "The whole local network failed" (S09's first option): local voice and garden telemetry contradict it, and a local-radio reset leaves the external fault unresolved. "One clear reading, let's go": `FR-03` keeps the hatch interlocked until the second reading.

**3 · Decision and escalation (the NASA way).** Steps 3–6 run under the same trade-study card with a fresh Go/No-Go before each commit; `FR-03` (storm hatch interlock; two readings below threshold ten minutes apart); the three-branch MER fault tree from 23 §7.3 step 3 isolates `F-EXT`; Ferreira's `EX-CH07-S09-L03` "Correct isolation was still the right decision." is the blame-free review in one line (the uplink loss is scripted, never a hidden penalty, 08). Risk card: "External uplink damaged", 4 × 4, HIGH (23 §7.2). **Escalation:** S07 meaning in the lull (why the seeds are called Alo, why the Academy has its name) → S08 the highest line on the chart → S09 a different silence: Earth does not answer. **Set piece:** S07 plays `SFX_RECORDER_AGED` while Mei holds the pressed petal near the case without pretending it can hear; S08 brings `CUE-09`'s full stems as the peak line rises and the shield bar does not move; S09 ends on `SFX_RADIO_EARTH_LOST` and Rao's empty channel. **Outcomes (mastery):** *success / Golden*: all six steps complete with `A > 0`, `Z ≤ 6` (witness `Z0`), `H > 0`, `C > 0`, founder 30 safe, `F-EXT` selected and two clear readings recorded, with no unsafe response committed. *Partial*: an alternative plan finished safely with `Z > 0`, or the local radio was reset before the external branch was chosen. *Failure*: an unsafe committed dose or air state, or a lost mandatory garden or seed objective, offers a pre-step retry (08).

**4 · Hints.** 08 P-14: H1 "Finish all three waves before going outside." · H2 "A working local radio isolates the failure to the Earth path." · H3 "Keep the six-step witness, select F-EXT and record two below-threshold readings." Progress report (`NEW`): H1 "How many steps are left?" · H2 "Claim only what the ledger already shows." · H3 "'The first wave is complete and the reserve is protected.'" **Modes:** Engineer labels the threshold 1.0 against Chang'e-4's 13.2 µGy/h quiet-Sun reference (the anchor proposed in SCIENCE_AND_DATA §B3-13, pending approval) and never as mSv.

**5 · Playtime and feel.** 10 + 10 + 10 minutes. *Hands:* play or read the log, arrange packet, page and ledger in a chain, commit steps 3–6, open the drain only after step 6 is sampled, run three branch tests, take two dosimeter readings across a time card. *Ears:* `SFX_RECORDER_AGED`, `CUE-09` stems, the shield-check tone each step, then `SFX_RADIO_EARTH_LOST` and a long quiet.

### 9.4 `EX-M0704` — The Days That Make a Journey

`EX-CH07-S10`..`S12` · Maintenance and care planning desk, fabrication bench and surveyed-route simulator, departure board and rover loadout · Prepares **P-15** and **P-16** · **25 min** · Data Cards: `esa_moonlight_relay` (terrain and curvature block direct line of sight at the south pole; relays fix it), `usgs_gazetteer_south_pole` (pole → Mons Malapert 121.9 km `[C]`), `jpl_ipn_42_176_dte` (best polar site: 51 % direct-to-Earth availability; some peaks keep a continuous view `[M]`), `bvad_2022_metabolic` · Outpost Status: dated stable-operation gates; the split home ledger (two people for 33 h, five for the final 3 h, 08 P-15).

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | The stable-operation board: care, planned food supply, atmosphere maintenance, observation, each with dated records. | INS | Planning desk (S10) | M, A |
| 2 | A draft plan that assumes an Earth reply; `EX-CH07-S10-L03` Kai: "No reply from Earth is in this plan." | OBJ + DLG | S10 | K |
| 3 | The sealed spare controller with Kai's December compatibility note, checked against the Malapert service housing. | OBJ | Fabrication bench (S11) | K |
| 4 | The terrain simulator: a straight line over the ridge fails its obstruction check; three repeater sites along the surveyed road; `EX-CH07-S11-L01` Rafi: "A high dish still needs to hear Aurora." | INS + DLG | Route simulator (S11) | R |
| 5 | The bench known-content echo test; a wrong connector stays on the bench with an explanatory mismatch; `EX-CH07-S11-L04` Amara: "A bench pass is not field verification." | INS + DLG | Bench (S11) | K, A |
| 6 | The journey card: 24 h out, 3 h repair, 24 h back, 72 h of independent provisions; `EX-CH07-S12-L02` Amara: "Two at home, then five for the last three hours." | LOG + DLG | Departure board (S12) | R (journey), A (home ledger) |

**2 · Deduction.** Local stability without Earth; a relay needs verified connectivity at *both* ends; consumption follows actual people and transitions. **Aha:** *"The summit dish must hear Aurora, not just see Earth."* **Wrong-but-reasonable:** "Wait for an Earth reply before maintaining systems" (S10's first option): the failed uplink makes that dependency unsupported. "Point the summit dish only toward Earth" (S11's first option): Aurora has no verified way to reach it. "Four occupants for the whole night" (S12's first option) disagrees with both the departure and return rosters.

**3 · Decision and escalation (the NASA way).** Three dated stable-operation gates (MP-05 consumables accounting) before the calendar may advance. A topology trade study ("summit dish only" versus "local repeater chain plus Earth dish"), with each leg testable separately. Bench ODF cards for connector and battery compatibility; Ferreira signs the isolation checklist (`EX-CH07-S11-L03`). Team assignment is a two-board Go/No-Go with `FR-05` (surveyed road only) and the 51 h ≤ 72 h provisioning check. Risk card: "Relay chain gap over a ridge", 3 × 4, HIGH. **Escalation:** S10 ordinary days, made to count → S11 building the network that the finale will depend on (T5) → S12 the separation. **Set piece:** five names face two destination boards; Mei and Kai exchange duplicate route and shelter checklists; Kai asks for the small guide light and Mei points to its place in the schedule (`EX-CH07-S12-L03`, `L04`). **Outcomes:** *success*: three gates passed, compatible spare, battery, three-site route and bench record packed, teams and both ledgers signed. *Partial*: a wrong connector or an obstructed site was caught and corrected on the bench or in the simulator. *Failure*: none destructive; the calendar simply does not advance until the gates pass.

**4 · Hints.** P-15 (08): H1 "A return reserve belongs in the departure plan." · H2 "Marker2 is part of the radio path." Topology (`NEW`): H1 "Who must be able to hear the summit?" · H2 "Draw both legs: Aurora to summit, summit to Earth." · H3 "Three repeater sites along the surveyed road, each in sight of its neighbours, plus the Earth dish." **Modes:** Family can place repeaters by tapping suggested pads that are all valid surveyed positions (no answer is marked); Engineer shows the 121.9 km distance and the 51 % availability figure.

**5 · Playtime and feel.** 8 + 9 + 8 minutes. *Hands:* tick three dated gates, tear up the Earth-dependent draft, match connectors, load the spare battery, run the echo test, place three repeater markers on the terrain model, hang five name tags on two boards. *Ears:* fans at their ordinary pitch, bench test tones, the quiet of an Earth channel that no longer answers.

---

## 10. Chapter 8 — *The Lighthouse* (`EX-M0801`–`EX-M0804`)

Chapter question: can two teams, a road of repeaters and a borrowed spare restore both voices and bring everyone home before first light? Mastery: both occupant ledgers safe and rover reserve ≥ 2, no blackout, relay plus live garden; Golden adds an unused emergency reserve.

### 10.1 `EX-M0801` — The Long Road

`EX-CH08-S01`..`S03` · Rover bay and departure board, rover route-planning console, surveyed road and first repeater sector · **P-15** departure and route · **30 min** · Data Cards: `viper_slope_limit` (15° `[M]`), `usgs_gazetteer_south_pole` (121.9 km `[C]`), `esa_moonlight_relay`, `bvad_2022_metabolic` · Outpost Status: two bars: rover `E14` (or 18 with the earned long-range battery, applied once) with allowances 5 out and 5 back and a minimum reserve of 2; home `E20/26, A8, H6, C8, R18, W0` on the COOL / DIM / basic loop (08).

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | The journey card; `EX-CH08-S01-L01` Rafi: "Twenty-four out. Three repair. Twenty-four back." and `L02` Amara: "Seventy-two hours of independent supplies." | LOG + DLG | Departure board (S01) | R, A |
| 2 | Packed hardware against the signed preparation manifest: compatible controller, battery spare, service diagram, three repeater checkpoints. | OBJ | Rover bay (S01) | K |
| 3 | The duplicate home-night checklist Mei passes to Kai. | OBJ | S01 | M → K |
| 4 | Route screen: surveyed road max 12°, allowance 5; shortcut 22°, allowance 3.5 (08); `EX-CH08-S02-L01` Kai: "The shorter line looks cheaper." | INS + DLG | Route console (S02) | K |
| 5 | The slope map over the same line; `EX-CH08-S02-L03` Ferreira: "A reserve cannot rescue an impossible road." | INS + DLG | S02 | R |
| 6 | Marker one passes its adjacent-link test; a timestamped position packet; `EX-CH08-S03-L02` Mei (Aurora local radio): "Position packet received." | INS + DLG | First sector (S03) | R, M |
| 7 | Marker two is dark; the console still shows a healthy surveyed pad, and an apparent bypass crosses an unsupported cliff route. | INS | S03 | R, K |

**2 · Deduction.** Provision the whole mission, not the first leg; optimise only inside the safety constraints (14 − 5 − 5 = 4 ≥ 2 on the road; 51 h ≤ 72 h); navigate by several references at once. **Aha:** *"The return is already in the battery."* (`EX-CH08-S02-L04`). **Wrong-but-reasonable:** "carry only enough for the outward leg" (S01's first option): departure waits. The shortcut looks cheaper (S02's first option): slope validation rejects it whatever its energy. At the dark marker, the visible bypass (S03's first option): the terrain overlay shows an unsupported cliff route, and Kai's hand stops on the steering control.

**3 · Decision and escalation (the NASA way).** Route trade study with `FR-05` (15° limit, reserve ≥ 2, 51 h ≤ 72 h, brake before any exterior repair); a dual-team Go/No-Go (Ferreira, Kai and Rafi in the rover; Mei and Amara at home, 23 P-15); the loadout ODF card (a missing spare blocks departure, 08). Risk card: "Shortcut 22°", 4 × 5, HIGH. **Escalation:** S01 separation made visible before the door closes → S02 commitment (cruise begins only after the rejected shortcut is explained) → S03 a problem in the dark. **Set piece:** `CUE-10` "Known Road" under the first cruise card; long shadows, black sky, the rover heard only through cabin and chassis; marker two sits dark on its surveyed pad. **Outcomes (mastery):** *success*: correct teams, complete loadout and provisions, surveyed route committed, marker-two pad reached with the brake set and a fresh position packet saved. *Partial*: the road was committed after the shortcut was rejected by the flight rule. *Failure*: off-road driving meets a slope barrier that offers a return to the last marker (08).

**4 · Hints.** 08 P-15: H1 "A return reserve belongs in the departure plan." · H2 "Marker2 is part of the radio path." · H3 "Use surveyed route, restore buoy 2, home heatMIN/lampDIM/returnOPEN." **Modes:** Family can drive any segment as guided cruise or watch from the station view; Engineer shows the gazetteer distance and VIPER's limit `[M]`, with road slopes `[G]` pending the LOLA pass (SCIENCE_AND_DATA §B3-14).

**5 · Playtime and feel.** 10 + 10 + 10 minutes. *Hands:* hang three name tags on the rover board and two on home, open crates against the manifest, hand over the checklist, lay the slope map over the route, steer three short playable segments, match the marker to the map with a bearing dial, set the brake. *Ears:* `SFX_ROVER_CABIN`, `SFX_ROVER_CHASSIS`, `SFX_RADIO_LOCAL_IN`, `CUE-10`.

### 10.2 `EX-M0802` — Two Teams, One Night

`EX-CH08-S04`..`S06` · Marker-two service pad and repeater chain, Aurora garden and life-support console, Aurora console and summit approach · **P-15** repair, home loop and summit arrival · **30 min** · Data Cards: `esa_moonlight_relay`, `bvad_2022_metabolic` (home air `A0.5` per 7.2 h for two, then `A1.25` for five: total 2.8125 `[C]`) · Outpost Status: home `E15` demand over 36 h on COOL / DIM / basic; 08's home witness ends `E5, A5.1875, H1, C8, R14.625`.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | The repeater's service drawing and battery specification; `EX-CH08-S04-L01` Kai: "Power isolated before the battery." | OBJ + DLG | Marker-two pad (S04) | K |
| 2 | Suit readiness and the tether point (`EX-CH08-S04-L02`). | INS | S04 | R |
| 3 | The marker lights, but two adjacent-link tests (1→2, 2→3) are still pending; `EX-CH08-S04-L03` Ferreira: "A light is not yet a link." | INS + DLG | S04 | K, R |
| 4 | The same independent gauge that exposed the misleading leak in Chapter 3, read calmly. | OBJ | Life-support console (S05) | A |
| 5 | The home loop: heat MIN (COOL), lamp DIM, water return OPEN (08). | INS | Garden (S05) | M |
| 6 | The occupancy forecast: two for 33 h, then five for 3 h; `EX-CH08-S05-L04` Mei: "Then five for the last three hours." | INS + DLG | S05 | A, M |
| 7 | Two packets: an older approach packet and a new summit packet with sender, location and time (`EX-CH08-S06-L03`, `L04`). | INS | Aurora console (S06) | A |

**2 · Deduction.** A powered marker is not a working link; home demand changes when people actually arrive; a message must be current enough for the decision it supports. **Aha:** *"A light is not yet a link."* **Wrong-but-reasonable:** "assume the whole chain works" when the marker lights (S04's first option). "Two occupants for the whole night" (S05's first option) forgets the returning three. "The earlier approach packet certifies arrival" (S06's first option): its location and time cannot. A home `returnCLOSED` setting prompts a thirst forecast instead of failing silently (08).

**3 · Decision and escalation (the NASA way).** The repeater ODF card (isolate → remove battery → compare specification → install → close housing → reconnect → test both neighbours); an unbraked exterior repair cannot start, and a link test run before the housing check names the missing condition (08). Home runs its own Go/No-Go before acknowledging any field message (`EX-CH08-S06-L01` Amara: "Home checks first. Then acknowledge."). Freshness checks on every packet (MP-08). Risk card: "Repeater chain gap", 3 × 4, HIGH. **Escalation:** S04 a repair in vacuum with careful hands → S05 the home team's long night begins (parallel responsibility, T8) → S06 the summit reached exactly 24 scenario hours after departure. **Set piece:** S05 opens on a viewpoint card naming Aurora and Mei; the Sun leaves at the scenario gate; Mei straightens one crooked nameplate and leaves the guide light where it was planned. S06 cuts, with a label, to Rafi at the summit and the dark relay housing beyond the rover window. **Outcomes (mastery):** *success*: three buoys linked 1→2→3, summit arrival 9 April 00:00, home loop and segmented forecast valid, fresh acknowledgement exchanged. *Partial*: a link test was attempted before the housing check and held, then completed. *Failure*: unbraked repair and stale-packet acceptance are blocked; nothing is lost.

**4 · Hints.** 08 P-15 hints as in 10.1. Freshness (`NEW`): H1 "When and where was this message sent?" · H2 "Compare it with the newest position you know." · H3 "Accept the packet whose sender, position and time match the planned 24-hour arrival." **Modes:** viewpoint cards always name who and where; no cadet switches between sites during free movement (08); Engineer shows both air rates.

**5 · Playtime and feel.** 10 + 10 + 10 minutes. *Hands:* clip the tether, open the isolation switch, swap the battery, latch the housing, press the link test for each neighbour; at home turn heat to MIN, lamp to DIM, return to OPEN, read the gauge; inspect packet fields. *Ears:* `SFX_SUIT_BREATH`, `SFX_BATTERY_SWAP`, `SFX_RADIO_LOCAL_IN`, the home fans at night pitch, `CUE-10`.

### 10.3 `EX-M0803` — Both Ends of the Light

`EX-CH08-S07`..`S09` · Malapert relay service bay, local antenna and Earth dish controls, relay data check and Aurora acknowledgement panel · **P-16** controller, links and checksum · **30 min** · Data Cards: `jpl_horizons_ch8_relay` (from Mons Malapert on 9 April 00:45–01:45 UT Earth sits at azimuth 357.9°–358.0°, elevation −2.3°, clearing a smooth horizon from ≥ 1.4 km up; from the pole it is 4.3°–6.7° below `[C]`), `usgs_gazetteer_south_pole` (bearing Malapert → Shackleton 176.7° `[C]`), `jpl_ipn_42_176_dte` · Outpost Status: the relay's two channels as two link bars; the home bar unchanged by the repair.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | The crate with Kai's December note; actual connectors and serial checked again (`EX-CH08-S07-L02`). | OBJ | Service bay (S07) | K |
| 2 | Power isolation and zero verification before removal; `EX-CH08-S07-L01` Ferreira: "Power isolated?" | INS + DLG | S07 | K |
| 3 | Two signal panels, each pairing strength with an obstruction indication; local presets L1 poor, L2 good, L3 blocked; Earth presets E1 poor, E2 blocked, E3 good (08). | INS | Antenna controls (S08) | K (dials), R (road chain) |
| 4 | Labelled scenario bearings (`Computed, no terrain`) from the fixtures. | CARD | S08 | R |
| 5 | The Aurora Earth-set handover window, shown as a planned deadline with an untimed equivalent (08). | INS | Aurora console | A |
| 6 | The ALO42 test: an exact current match, a near match and an older saved packet in the diagnostic preview; `EX-CH08-S09-L01` Rafi: "Strong is not the same as correct." | INS + DLG | Data check (S09) | R |

**2 · Deduction.** The right part still needs the right procedure; a relay is useful only when *both* legs pass on their own evidence; a strong signal can still carry wrong content. **Aha:** *"Both shores, not just the bright one."* (`EX-CH08-S08-L04`). **Wrong-but-reasonable:** "reset the damaged controller while live" (S07's first option): removal stays blocked until isolation and zero are verified. Point at Earth first because Earth is the goal and its image shows above the ridge: the local leg must pass on its own first (`EX-CH08-S08-L01` Kai: "Aurora first."); "Earth signal strong, local leg unverified" (S08's first option) leaves Aurora with no checked path. Accept a similar-looking or older reply (S09's first option): it fails the exact-current-match rule.

**3 · Decision and escalation (the NASA way).** The ODF controller replacement (isolate → verify zero → remove → install compatible spare → close housing → reconnect, `FR-04`; reconnecting with the housing open is blocked, 08); MER step 5 end-to-end verification per leg with a stable 3-second lock or tap-confirm; the exact checksum; voice checks kept as an explicit next step (`EX-CH08-S09-L04`). Risk card: "Live controller removed", 2 × 5, HIGH, interlocked. **Escalation:** S07 a precise repair → S08 aiming both shores against the Earth-set window (pressure without motor timing) → S09 the data has to be exactly right. **Set piece:** nothing sparks in vacuum; `SFX_CONTROLLER_POWERUP` wakes the antenna panel with two unverified channels; the score stays quiet enough for checkbacks. In S09 the returned characters A-L-O-4-2 settle beside the sent string one by one. **Outcomes:** *success*: compatible controller installed and housing closed before power, L2 then E3 locked and stable, ALO42 matched exactly, both voice checks prepared. *Partial*: a wrong preset was tried and changed after its strength-and-obstruction text (the assisted preset path is rewarded equally, 08). *Failure*: unsafe steps are blocked; a link lost during the test reuses the checkpoint and transcript (08).

**4 · Hints.** 08 P-16: H1 "A relay needs both ends." · H2 "Connect Aurora’s repeater chain before Earth." · H3 "L2 thenE3, checksumALO42, verify both voices; return and open the safe shutter." **Modes:** Family and accessible input use the L/E presets and tap-confirm (equally rewarded); Engineer shows azimuth and elevation from Horizons and the gazetteer with their `[C]` tags.

**5 · Playtime and feel.** 10 + 10 + 10 minutes. *Hands:* unlatch the crate, read the serial, isolate and meter zero, pull the old controller and seat the spare, close the housing, reconnect; turn azimuth and elevation dials; send the test string and compare. *Ears:* `SFX_CONNECTOR`, `SFX_CONTROLLER_POWERUP`, suit breathing, checkbacks over a near-silent score.

### 10.4 `EX-M0804` — From Last Light to First Light

`EX-CH08-S10`..`S12` · Rover cabin, Aurora and Noor's Earth rooftop; pressurised rover and arrival airlock; Aurora pressurised garden · **P-16** voices, return and final garden · **30 min** · Data Cards: `jpl_horizons_ch8_relay`, `nssdca_moon_light_time` (in `game/resources/data/nasa_practice/`: about 1.3 s one way, 2.6 s round trip `[C]`) · Outpost Status: home occupancy switches from two to five at 03:00 on 10 April; the final five checks sit on the shutter panel.

**1 · Investigation**

| # | Clue | Kind | Where | Holder |
|---|---|---|---|---|
| 1 | Both path checks visible before the transmit control unlocks; then `EX-CH08-S10-L01` Noor (first live Earth voice): "Hello, Aurora. This is Noor." | INS + DLG | Rover cabin / Aurora / rooftop (S10) | All |
| 2 | The light-time chip on the Earth channel; the crew leaves pauses for radio delay. | INS + CARD | S10 | A |
| 3 | Current garden telemetry and the preserved lineage photograph sent to Noor. | INS | Aurora (S10) | M |
| 4 | Actual round-trip use against the whole-mission forecast; `EX-CH08-S11-L01` Rafi: "Return is part of the mission." | INS + DLG | Rover (S11) | R |
| 5 | Three return route gates with new timestamps; `EX-CH08-S11-L02` Kai: "Same road. New timestamps." | INS + DLG | S11 | K |
| 6 | The arrival check (three names, pressure procedure) and the occupancy change; `EX-CH08-S11-L04` Mei: "Five home. Three hours to first light." | INS + DLG | Airlock (S11) | A, M |
| 7 | Five final checks before the shutter: crew 5 safe; founder reserve 30 and eleven unplanted vault specimens protected; pressure stable; temperature stable; cotton alive (08). | INS | Shutter panel (S12) | R (crew), A (pressure), K (temperature), M (seeds, cotton) |

**2 · Deduction.** A shared achievement has many contributors; consumption belongs to the place actually supporting each person; the last safety check comes before the most beautiful moment. **Aha:** *"The garden has more than one gardener."* (`EX-CH08-S10-L04`). **Wrong-but-reasonable:** "The relay crew alone saved the garden" (S10's first option): the debrief shows the home care and earlier work that made it possible. Raising home consumption when the rover leaves the summit (S11's first option): those people are still supplied by the rover. Opening the shutter as soon as everyone is home: the shutter waits for its safety checks (08).

**3 · Decision and escalation (the NASA way).** CAPCOM voice protocol through Rao with closed-loop voice checks at both ends (23 MP-08); the return runs on the same forecast and reserve rules (`FR-05`); the final five-person Go/No-Go before the sunrise shutter (23 P-16, `FR-06`). Risk card: "Shutter opened before final checks", 1 × 4, MODERATE (interlocked). **Escalation:** S10 the voice the whole game waited for → S11 the discipline of the same road home → S12 first light. **Set piece:** `CUE-11` "Hello Aurora" across a labelled three-way cut (summit cabin, Aurora table, a Bangladesh rooftop with no unsupported claims about Moon phase); in S12 `SFX_SHUTTER_OPEN` and `CUE-12` "What We Grew" reveal mustard descendants flowering, cotton by the window and Alo's petal beside the lineage label with Tara's contribution beside Alo's. The garden's posture is the payoff: every stem upright toward the window, never a face. **Outcomes (mastery):** *Golden*: everything below with the rover's emergency reserve unused. *Success*: both voices and telemetry acknowledged, return started at 03:00 and completed at 03:00 on 10 April, five final checks passed, photo and dedication saved. *Partial*: the emergency reserve was used but the minimum held (Golden lost). *Failure*: a link lost during the call reuses the checkpoint and transcript; the shutter never opens early (08).

**4 · Hints.** 08 P-16 H3 as in 10.3. Final checks (`NEW`): H1 "What must be true before you open a window to the Sun?" · H2 "People, seeds, pressure, temperature and the cotton." · H3 "Crew 5 ✓ · founder 30 and vault 11 ✓ · pressure ✓ · temperature ✓ · cotton alive ✓ → open the shutter." **Modes:** Engineer shows the light-time arithmetic (384,400 km / c) `[C]`; the credits and photo are identical in every mode.

**5 · Playtime and feel.** 10 + 10 + 10 minutes. *Hands:* press transmit only after both checks, confirm two voice checks, choose the report sentence, read the return margin, confirm three route gates, cycle the airlock, tick five final checks, pull the shutter lever, frame the shared photograph, choose a dedication. *Ears:* `CUE-11` with real round-trip pauses, `SFX_ROVER_CABIN`, `SFX_AIRLOCK_CYCLE`, `SFX_SHUTTER_OPEN`, `CUE-12` into the credits.

---

## 11. Proposals and open questions for the user (nothing here changes canon or 08)

1. **Retire or rewrite `19_TRAINING_DECISIONS.md`.** It contradicts canon (cast, crop, puzzle contracts, fixture IDs), and its §10 proposals cite numbers that are not in 08. This file now covers its per-mission content and a banner at the top of 19 says so. Follow-up task `M1-41` asks for the user's choice: shrink 19 to a pointer to this file, or rewrite it to canon. `docs/REQUIREMENTS_ALIGNMENT.md` (written in the same task as 19) should be checked for the same drift.
2. **Pending science-label proposals this design leans on** (from SCIENCE_AND_DATA §B3; still awaiting approval): P-02 shift-4 Earth-link cutoff (B3-5: approved 4 Nov 2026 and applied; Earth is below the pole's horizon 15–28 Apr 2046 and rising, JPL Horizons <https://ssd.jpl.nasa.gov/api/horizons.api>); P-05 gauge labelled as % of 101.3 kPa (B3-7); "0 Z at S6" shown as "below the storm limit" (B3-3, B3-12); P-14 threshold anchored to Chang'e-4's quiet-Sun dose (B3-13). Each section marks where the label appears; the numbers stay as they are.
3. **The P-05 aftershock as a story beat.** 08 puts it at phase 2; this design plays it during `EX-CH03-S02` with the same cup that rattled in `EX-CH02-S12` and uses it as the in-world reason the annex hatch cover is displaced. No dialogue or number changes; please confirm the placement.
4. **Partial-success display.** This design shows partial success only in the debrief and the existing [G] mastery stars, never as a lower ending. Confirm that no separate "partial" badge is wanted.
5. **Risk-card ratings.** Hazards already in 23 §7.2 keep their ratings; the others in this file (for example "Uncalibrated reading used for planting", 3 × 3) are new `[G]` teaching values. Approve or adjust them in one pass.
