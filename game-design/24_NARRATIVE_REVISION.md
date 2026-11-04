# 24 — Narrative Revision: one connected journey from the first seed to the final garden

- **Date:** 5 November 2026 · **Author:** Claude Code (Opus 5.5) subagent for Sadman · **Status:** design proposal. Nothing here is canon until Sadman approves it.
- **Board tasks created from §8:** `M1-47`..`M1-52`, `M3-94`..`M3-99`.
- **Canon this document obeys (it never overrides them):**
  - Story, scenes, dialogue and chronology: [`full-game-story/STORY_FULL.md`](../full-game-story/STORY_FULL.md) and [`story-data.json`](../full-game-story/story-data.json). Scene ids are `EX-CHxx-Sxx`; line ids are `EX-CHxx-Sxx-Lnn` and are quoted word for word.
  - Numbers and puzzle rules: [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) (`P-01`..`P-16`). No number in this file is new.
  - Clues, deductions, hints and mission feel: [`22_PUZZLE_CLUE_DESIGN.md`](22_PUZZLE_CLUE_DESIGN.md). This file builds on 22 and does not repeat it; "22 §5.3" means that section of 22.
  - NASA practice: [`23_NASA_MISSION_PRACTICE.md`](23_NASA_MISSION_PRACTICE.md). Data Cards: [`mission_data_cards.json`](../game/resources/campaign/content/mission_data_cards.json).
  - Locked decisions: [`PRODUCTION_HANDBOOK.md`](../PRODUCTION_HANDBOOK.md) §3–§4. English only; the seed packet reads "ALO" and "N." in Latin letters; plants never have eyes, faces, mouths or speech; adult characters only; no NASA logos or implied endorsement; Moon science rules in [`ART_BIBLE.md`](../production/ART_BIBLE.md) §2.
  - Chapter 1 science review, approved 4 Nov: [`science_review_ch01.md`](../production/review/science_review_ch01.md). The shift-4 loss of Earth contact is an **Earth-link cutoff (authored training event)**, because Earth is below the pole's horizon from 15 to 28 April 2046.

## How to read the change labels

Every proposal carries one label. Only the last two touch canon.

| Label | Meaning | Who signs it off |
|---|---|---|
| `STAGING` | Camera, blocking, animation, light, sound or silence around existing lines. No new words. | Task owner |
| `TEXT` | New written world text: a journal entry, a label, a note on a prop, a hint. Never spoken. (22 calls this `NEW`.) | Task owner; Sadman sees it in review |
| `CODE` / `ASSET` / `AUDIO` | Implementation work. | Task owner |
| `[STORY CHANGE — needs Sadman's approval]` | A new or changed story fact (a date, an event, an outcome) with no new spoken line. | Sadman, before any work |
| `[CANON CHANGE — needs approval + re-recording]` | A new or changed spoken line. The 383 recorded lines are canon; each change needs Sadman's approval and an ElevenLabs re-record. Every one in this file has a no-voice alternative that uses existing lines. | Sadman, before any work |

Plain-language rule for the whole document: **we add meaning through what the player does, sees and hears, and we add as few new words as possible.** The whole revision proposes **3 new spoken lines** (all optional) and **0 changed lines**.

---

## 0. The seven rules of a connected journey

These are the rules every section below applies. They answer Sadman's 4 November request ("one scene to another scene but totally connected … people should feel attached … like Death Stranding … easily playable and fun to all people") as working principles. Techniques are taken from premium narrative games as principles only; no names, characters or content are copied.

1. **Every scene hands something to the next.** An object, a question, a sound, a task or a line leaves one scene and arrives in the next. §2.9 lists the bridge for all 95 scene-to-scene joins and the 7 chapter joins.
2. **Emotion comes through the hands.** Attachment is built by quiet, physical, repeated work: holding a lamp steady, photographing a leaf in the same frame as yesterday, counting seeds together, mounting a beacon. Grief and joy arrive in scenes the player has worked for.
3. **Every voice travels over something the player built or checked.** People are separated by distance (Earth, Aurora, the rover, the summit). Each voice in the finale crosses beacons, repeaters, a controller and a dish the player prepared (22 T5, T8). The connection is earned, never given.
4. **The mystery is honest.** Clues are physical, dated and sourced. Characters never hide safety information. The Evidence board keeps blanks blank until a record fills them (22 T2).
5. **Choices are remembered, not punished.** Interpretation, preparation and relationship choices leave visible traces in later scenes and in the journal. Outcome-changing choices stay inside the systems that already change outcomes: the P-02 endings, the earned upgrades and mastery stars.
6. **Silence is an instrument.** No airborne sound in vacuum. Music stops for grief. The 2.6-second radio round trip becomes a held breath in the finale.
7. **Easy to start, deep to master.** One new verb per scene in Chapter 1, an objective always visible, three-tier hints, and Family / Cadet / Engineer modes that change pressure and detail, never the story (22 §2.3–§2.4).

Narrative techniques borrowed (principles only; 22 §1 lists the puzzle principles T1–T10):

| ID | Principle | Where it shows up |
|---|---|---|
| N1 | **Infrastructure as relationship.** What you place on a road later carries the people you care about. | CH04 beacons, CH07–CH08 repeaters, ALO42, Noor's first live voice (§7.5) |
| N2 | **The recurring object.** A small object returns changed, and the player recognises the change before anyone speaks. | The hand light, the mugs, the paper bee, the pressed petal, Tara's nameplate, the inventory lamp (§3, §7) |
| N3 | **The player's own record is the reward.** The final images are the player's photographs, labels and choices, not a new cinematic. | Growth Record (§3.8), final photo (§7.6) |
| N4 | **Quiet after the storm.** Every crisis is followed by a recovery beat where hands slow down and people talk briefly. | CH01-S11/S12, CH03-S05, CH06-S11, CH07-S10, CH08-S11 (§2) |
| N5 | **The voice becomes a person.** A voice the player has only heard (Ferreira, Noor) gains weight, a chair, a mug and a pause. | CH05-S01 (Ferreira), CH08-S10 (Noor) |
| N6 | **Letters along the road.** Messages arrive late, are kept and are read again. Delay is part of the relationship. | N.'s recordings, Noor's texts, Rao's listening log (§4) |

---

## 1. Audit

### 1.1 Strengths to keep

- **A complete, causal spine.** 96 scenes, 32 missions, a dated chronology from 11 Apr 2046 to 10 Apr 2047, and transitions that mostly hand over cleanly (`transitionOut` in story-data.json). Chapter 2 → 3 is seamless ("No date jump follows the quake").
- **Honest science, built in.** Every scene carries an evidence tag (Simulated, Fiction, Computed-pending); the 2017 replay and 2012 counterfactual are labelled; sources and claim boundaries close STORY_FULL.
- **Strong recurring objects already exist:** the four unnamed mugs → fifth mug (CH01-S01 → CH04-S12 → CH05-S01 → CH08-S11); Kai's hand light (CH01-S05 → CH06-S01 → CH07-S12 → CH08-S04); the paper bee (CH02-S02 → S07); the pressed petal (CH03-S10 → CH08-S12).
- **Ferreira's confession is well placed** (CH05-S05, after the records in S03 and S04) and the story already insists that she never withholds safety information (CH03-S03 "Safety information does not wait.").
- **Alo's death is handled as natural completion,** not failure (CH03-S09 Amara: "This is maturity, not the old cold alarm."; S10 "It meant she could finish.").
- **Noor's reveal order is sound:** anonymous N. (CH01–CH04) → signed identity with consent (CH05-S10) → text (CH05-S12, CH06-S09) → historical last log (CH07-S07) → first live voice after both links pass (CH08-S10).
- **Choices exist in every scene** (96 decision reviews with option ids `EX-CHxx-Sxx-OPTnn` in the catalog) and every wrong idea runs in a paused preview (22 T10).
- **Accessible by design:** Family / Cadet / Engineer modes, Solo / Class, timer-free planning, captions with origin labels (`LOCAL LIVE`, archive, Earth link).

### 1.2 Gaps

1. **Choices converge without a trace.** All 96 decision reviews converge (by design), but nothing records which option the player chose. `CampaignState.new_snapshot()` has no choice store; `campaign_panels.gd:329` emits `preview_puzzle` with an `option_id` and the director keeps no record of it. A player cannot see that a choice mattered later.
2. **The journal is a flat list.** `CampaignKnowledge.journal()` returns acquired-evidence records with observation labels; `_render_journal()` prints them as one column. The designed tabs (13_UI_UX_DESIGN, UI_07: Mission, People, Garden, Evidence, Science), the Observed / Inferred / Unknown board (22 T2) and a resume summary do not exist yet.
3. **Alo's growth is told, not seen.** The care sequence in CH01-S05 lists tasks but has no repeatable photo record, so "Alo's growth step by step" depends on cutscenes. Art has Alo sprout, bud, bloom and pods (ASSET_PL_Alo_*), but no cotyledon, true-leaf or senescent (yellowing) state.
4. **Tara is equal in principle, thin in practice.** Tara has one bloom model (ASSET_PL_Tara_Bloom), no pods, no senescence, no archived object, and no ending of her own. Canon never says what happened to Tara's pods, although the reciprocal runs (CH02-S04: "Transfer Tara pollen to Alo and Alo pollen to Tara") mean Tara set seed too.
5. **Ferreira's history has no subtle signs before CH05.** The engineer voice (CH02-S10) is the only clue to her role. Her guilt is described in the character bible but not staged before the confession.
6. **Noor goes quiet between clues.** CH03–CH04 carry the annex and vault, but there is no small personal trace of N. (a handwriting habit, a note, a reason for choosing cotton). After the CH05 reveal, curiosity rests on two texts.
7. **Rao has no arc on screen.** Rao covers Ferreira's hesitation (CH04-S11) and delivers the identity page (CH05-S10), then disappears behind the CH07 blackout without a beat that shows what silence cost Earth.
8. **The opening has stakes but no image.** CH01-S01 opens on a battery display. There is no establishing image that gives the game a visual identity (mustard gold against regolith grey) or plants the yellow fields that pay off in CH02-S10, CH07-S07 and the CH08-S10 rooftop.
9. **Montages risk feeling like gaps.** CH03-S12 (five months), CH04-S12 (seven weeks), CH06-S12 (one month) and CH07-S10 (two months) cover long intervals. Canon requires dated work inside them; the human content of those weeks is not specified.
10. **Chapter-end hooks lean on danger twice** (CH02 quake, CH06 new warning). The other six vary well.

### 1.3 Continuity risks (found while reading)

| # | Risk | Evidence | Fix (section) |
|---|---|---|---|
| C1 | **Tara's natural end is coded but never shown.** The plant service marks Tara `naturally_dead` once she passes `mature_days + 5` (day 41, 22 May 2046) with `seed_yield` 0, while 08 keeps Tara's live irrigation on during Alo's dry-down. | `game/scripts/biology/plant_service.gd` `advance_to()`; 08 P-06 "selecting Tara's live irrigation displays wrong plant" | §3.9, §7.6 (proposed resolution) |
| C2 | **CH08-S10 prose describes words nobody speaks.** Prose: "Rao identifies the restored route" and Noor "says the crew did what she could not". Neither is a line in S10's dialogue. | story-data.json EX-CH08-S10 `prose` vs `dialogue` | §7.5 |
| C3 | **CH05-S05 prose carries Ferreira's account, the lines do not.** The seed drawer, the cooling annex and "a gardener who believed another crew would come" are prose only. | EX-CH05-S05 | §7.4 (records carry it as `TEXT`) |
| C4 | **Earth in the sky.** The approved science review computed Earth below the pole's horizon 15–28 Apr 2046. Any opening or CH01 shot that shows Earth rising or setting over Aurora is wrong until M1-34/M1-36 verify terrain. | science_review_ch01 B1; ART_BIBLE §1 "Earth remains omitted" | §7.1 keeps Earth on screens only |
| C5 | **Bangla script and plant eyes in older docs.** STORY_FULL line 7 is a Bangla sentence; the character bible gives Alo "stylised eyes" (line 53) and uses Bangla names. Not player-facing, but a writer copying from them breaks the locks. | STORY_FULL.md:7; 04_CHARACTER_BIBLE.md:53, :59 | §8 NR-14 (docs pass after approval) |
| C6 | **The 24 written N./Noor logs** in docs/GAMEPLAY_DESIGN_FINAL.md ("A drawer is a small place to leave a big hope.") are not in STORY_FULL and not recorded. They are good text, but their status is undecided. | GAMEPLAY_DESIGN_FINAL.md, "24 log catalogue" | §4 uses three of them as written notes (`TEXT`), never voiced |
| C7 | **CS-15 and CS-17 are still being made.** CS-15 is 26.5 s with shots A–C generated and D planned; CS-17-C/D are only planned (notes_C.md). Staging changes for the finale must reach that lane before it finishes, or they cost a remake. | production/cutscenes/v8/notes_C.md | §8 NR-09 is time-sensitive |
| C8 | **The journal masks Noor's name by keyword.** `grant_operation()` replaces any observation label containing "noor" until `noor_identity_revealed`. A label that names her another way (for example "N.R. is Rahman") would leak. | knowledge_service.gd | §6.5 spoiler rules |
| C9 | **Save schema is strict.** `validate_snapshot()` rejects a save missing any default key, so a new choice store needs a schema bump (2 → 3) with a migration in `SaveService.migrate()`. | campaign_state.gd, save_service.gd | §5.4 |

### 1.4 Feature status (every requested feature)

| Requested feature | Status | Evidence | Where this file answers it |
|---|---|---|---|
| Deliberate Noor clue sequence | Needs strengthening | 21 canon clues exist (CH01-S03 → CH08-S10); CH03–CH04 and post-reveal are thin | §4 |
| Noor identity reveal in CH05, first live voice in CH08-S10 | Exists | CH05-S10, CH08-S10 | §4, §7.5 |
| Distinct character arcs with vulnerability, contribution and change | Exists for cadets; needs strengthening for Ferreira, Rao, Noor | 04_CHARACTER_BIBLE development lines; Rao has 4 spoken lines in the whole game, Noor 5 plus N.'s 2 | §3 |
| Ferreira's subtle signs before the confession; gradual change after | Missing (before); exists in canon beats (after) | Only CH02-S10 voice before; CH06-S01, CH07-S01, CH08-S07 after | §3.5, §7.4 |
| Attachment to Alo through varied, repeated care | Needs strengthening | CH01-S05 care list; no photo record | §3.8, §7.2 |
| Alo's growth shown step by step, scientifically correct | Needs strengthening | Code stages exist; art lacks cotyledon, true-leaf, senescent | §3.8 table |
| Tara comparable care and significance | Needs strengthening | One bloom model; equal framing in 22 §4.2 | §3.9, §7.6 |
| Alo's natural end-of-life scene with the player taking part | Exists (CS-06); needs strengthening | CH03-S09/S10, CS-06 20.1 s | §7.3 |
| Tara's final outcome | Missing in canon | C1 above | §3.9 (proposed, labelled) |
| Choices with observable, persistent consequences | Missing persistence | Gap 1 | §5 |
| Distinct gameplay emphasis per chapter | Exists | 22 §3–§10, 08 | §2 (one row per chapter), §2.10 |
| Short learning challenges inside tasks | Exists | Every scene's `learning` block; 22 Reference Ladder | §2 rows, §2.10 |
| Recoverable mistakes with specific feedback and retry | Exists | 22 §0 outcome tiers; P-02 checkpoint retry | §2.10 |
| Constructive failure debriefs | Exists for CH01; needs a standard for CH02–CH08 | execution/ENDING_*.md | §2.10 |
| Mission journal | Partial (flat list) | Gap 2 | §6 |
| Strong cinematic opening | Needs strengthening | Gap 8 | §7.1 |
| Mystery in the annex and abandoned spaces | Exists (CH03-S06/S07, CS-05); needs environmental detail | 22 §5.3 | §2 CH03 row, §4 |
| Music, sound and silence with specific cues | Exists (CUE-01..12, 35 SFX) | music_cues.csv, sfx_list.csv | §2 rows, §7 |
| Lunar sound rules | Exists | 15_AUDIO; ART_BIBLE §2 rule 7 | §2.11 |
| Noor's first live call cinematic | Exists (CS-15 in production); needs anticipation, pauses, three-place sound | notes_C.md | §7.5 |
| Captions, transcripts and visual cues | Exists | origin labels in dialogue catalog | §6, §7 |
| Natural, distinct dialogue | Exists; a few prose-only lines (C2, C3) | | §3 voice notes, §7 |
| Smooth transitions, varied chapter hooks | Mostly exists; four montage gaps, two danger hooks | Gaps 9–10 | §2.9, §2 rows |
| Real data vs simulation vs counterfactual vs fiction | Exists; can add two real observations | Evidence tags | §2.12 |
| Ending ties Alo, Tara, seeds, crew and the player's records | Needs strengthening | CH08-S12 | §7.6 |
| Mars teaser with one restrained detail | Needs strengthening | CS-18 is a closed-drawer still | §7.7 |
| Easily playable, fun puzzles that teach | Exists (22); needs an onboarding rule set | | §2.10, §7.1 |

---

## 2. Chapter-by-chapter revision

Each chapter has one table with the same eight rows. "Canon" marks what already exists; everything else is a proposal with its change label. Clue and hint detail per mission stays in 22 (cited by section).

### 2.1 Chapter 1 — *Night One* (`EX-CH01-S01`..`S12`, 11–27 Apr 2046, 75 min)

| Field | Revision |
|---|---|
| **Narrative and emotional development** | Canon arc: curiosity → shared care → prepared fear → controlled crisis → earned relief. Revision: make Alo **and** Tara personal before the night. Each gets her own Care Round (§7.2) in S04–S05, with a dated photograph taken by the player in the same frame each visit, so that by S09 the player has watched both plants grow. Kai's fear is seeded by the second switch click (S05, canon) and answered by Rafi's hand light (canon). The four nameless mugs (S01) get names after the bloom (S12, `STAGING`): the canon sentence "Aurora has become their station" becomes something the player does. |
| **Distinct gameplay challenge** | **Resource planning and preparation under scarcity.** P-01 calibration and planting (S03–S04); P-02 seven-shift Mission Table plan with PUMP / STACK / WAIT (S06–S11). 22 §3.1–§3.4. |
| **Mystery clue and payoff** | Canon: the packet reads ALO and N. (S03); the stored N. recording plays when the player tags the bloom photo (S12). New `TEXT` (§4 clue 2): inside the drawer lid, a pencilled planting plan for two seeds, "Alo — outer chamber / Tara — indoor bench", with the third line stopping mid-word. It establishes that N. named **both** seeds and planned this exact pairing. Payoff: CH05-S05 (the seed drawer in Expedition Zero's final minutes) and CH07-S07 (the name). |
| **Important choice and later consequence** | `EX-CH01-S04-CHOICE` (paired photographs or paired conditions table) sets the layout of the **Growth Record** for the whole campaign; the player sees their own format again in CH03-S10, CH04-S01 and the final photo (§5). `EX-CH01-S01-CHOICE` (store air or light the bay) returns as a framed first-day photo beside the CH08-S05 home loop. The outcome-changing choice is P-02 itself (Golden Bloom, Bloom, Alo Lost, Mission Stopped; 08, M1-19). |
| **Learning objective** | Storage limits and useful loads (S01); local versus live-link information (S02); measurements need references (S03); conservation and sequence (S08, S11). Learning beat: the player predicts what a full store does with more input **before** the overflow preview runs (S01), then applies the same rule to shelter water in S08 and S11. |
| **Visual and audio direction** | Opening: silent exterior, fans inside (§7.1). `CUE-01` enters after the charter (canon); `CUE-02` for planting and care; `CUE-03` at the sunset gate (S09), then silence after `SFX_RADIO_EARTH_LOST`; `SFX_FAN_LOWPOWER` through the dark shifts; `SFX_ALERT_PARTICLE` is an instrument tone, never a projectile; `SFX_HATCH_SEAL`. S12: `SFX_SHUTTER_OPEN`, `CUE-04` on the first petal, ducked under N.'s recording (`SFX_RECORDER_AGED`). Colour motif: the mustard-gold battery band (`#F2C230`) in S01 becomes the first petal in S12. |
| **Transition and chapter-ending hook** | Hook (emotional question and new objective): N.: "If you are hearing this, Alo bloomed. Good. Now Alo needs a friend." (`EX-CH01-S12-L02`). Bridge to CH02: the date card shows the player's three photographs of Tara's bud (27, 28, 29 Apr); on 30 Apr the Earth console lights (`SFX_RADIO_EARTH_IN`) as Tara opens. |

### 2.2 Chapter 2 — *Be the Bee* (`EX-CH02-S01`..`S12`, 30 Apr–6 May 2046, 75 min)

| Field | Revision |
|---|---|
| **Narrative and emotional development** | Canon arc: recognition → patient precision → curiosity → tentative personal connection → decisive reprioritising. Revision: frame Alo and Tara at equal size in every shared shot (`STAGING`; ART_BIBLE §6). Mei's grandmother's orchard (S02) is told through the paper bee and her hands, not a speech. The first human connection to N. (S10) is staged as Mei alone at the playback station, the others a step behind her. |
| **Distinct gameplay challenge** | **Botanical care and precision handling**, then **record investigation.** P-03 sealed reciprocal pollination route (S01–S06); P-04 recorder metadata reconstruction (S07–S10). 22 §4.1–§4.4. |
| **Mystery clue and payoff** | Canon: equipment number (S07), label under label (S08), 2034 reconstruction (S09), engineer voice and N.'s yellow fields (S10). New `STAGING`: N.'s line "My grandmother’s mustard fields turned yellow every winter. I wanted some of that light here." (`EX-CH02-S10-L03`) plays over a two-second hold on the photo the player has carried since the opening field (§7.1), so the player recognises the image. Ferreira sign: the package goes to her (S11) and her reply stays "pending" through the quake (canon). Payoff: CH05-S05 and CH05-S10. |
| **Important choice and later consequence** | `EX-CH02-S06-CHOICE` (the stem-colour prediction) already pays off in CH04-S01. Strengthen: show the **reason the player wrote** beside the October count. `EX-CH02-S10-CHOICE` (resemblance as proof or as inference): the Evidence board files the voice under Inferred; in CH05-S03 the card reads "Kept as an inference since 6 May" (`TEXT`), which rewards the honest choice without punishing the other. |
| **Learning objective** | Pollination moves pollen and is not seed formation (S02, S04); a route includes its return (S03); predictions stay revisable (S06); inference differs from observation (S10). Learning beat: rehearse on the nonliving flower model (S02), then do it once for real (S04). |
| **Visual and audio direction** | `SFX_GLOVE_PORT`, `SFX_BRUSH_CONTACT`, `SFX_AIRLOCK_CYCLE`; `CUE-02` for the seven care days; `SFX_RECORDER_AGED` under both 2034 voices. S11 is deliberately quiet (fans only) so `SFX_CUP_RATTLE` reads before `SFX_QUAKE_CONTACT`, `SFX_ALERT_STRUCTURAL` and `SFX_ALERT_PRESSURE` (CS-04). |
| **Transition and chapter-ending hook** | Hook (sudden danger, canon): the cup trembles. No time jump; Chapter 3 starts at 22:05 with the same red warning. |

### 2.3 Chapter 3 — *Moonquake* (`EX-CH03-S01`..`S12`, 6 May–21 Oct 2046, 85 min)

| Field | Revision |
|---|---|
| **Narrative and emotional development** | Canon arc: alarm → uncertainty admitted → evidence-based control → discovery → grief → continuation. Revision: give the five-day dry-down between S09 and S10 a vigil (§7.3): one photo a day in the same frame, so the player watches Alo finish. Add Tara's own farewell as the first beat of S12 (`[STORY CHANGE — needs Sadman's approval]`, §3.9). |
| **Distinct gameplay challenge** | **Diagnosis and repair** (P-05 fault localisation with the independent gauge, S01–S05), then **end-of-life care and an exact harvest ledger** (P-06, S09–S11). 22 §5.1–§5.4. |
| **Mystery clue and payoff** | Canon: N.R. hatch (S06), frozen unflowered seedlings, 2034 service tag, route sheet (S07), vault map (S08). New `ASSET`/`STAGING`: a tool tag on the warm-side bench carries the same frayed gear-wheel emblem as Ferreira's old engineering patch (ART_BIBLE §5), which the player has seen on her Earth screen since CH01. New `TEXT`: the annex growth chart's last handwritten line stops at "Day 12. Leaves curling. Heat" (an incomplete record, no claim). Ferreira's line "An isolated annex. Use the supplied boundary checks." (`EX-CH03-S06-L03`) is preceded by a one-second pause and a glance off-screen (`STAGING`). Payoff: CH05-S03/S05. |
| **Important choice and later consequence** | `EX-CH03-S11` dedication: the player picks the tray's dedication after the scientific labels (canon: "Mei lets everyone choose a dedication"). Three `TEXT` options: "Light and Star", "For Alo and Tara", "The Next Small Thing". Kai's "Very Important Scientific Plant" (`EX-CH03-S11-L03`) goes on cassette 1 whichever the player picks, as canon allows ("After its lineage label. Then yes."). The chosen words appear on the descendant rack in CH04-S01 and on the lineage board in the final garden (§5). Outcome: P-05 mastery (wrong isolations). |
| **Learning objective** | A warning is not a diagnosis (S01); a hypothesis must explain every reading (S02); a completed action is not a verified repair (S04); maturity, drying and harvest are different stages (S09); inventories are conserved, 42 = 12 + 30 (S10–S11). Learning beat: the player predicts which tap falls before taking readings (S02), and later predicts which trace a patch should change (CH05-S08), the same skill one constraint harder. |
| **Visual and audio direction** | Manual gauge needle as the hero object of S01–S05. S07: suit breathing and local radio only (`SFX_SUIT_BREATH`, `SFX_RADIO_LOCAL_IN`), visor view, no fog or haze, frost on the trays. `CUE-05` in the annex and the harvest, stopping under the count so only `SFX_SEED_TICK` is heard; `CUE-05` returns quietly for planting (canon); `CUE-02` through the montage. Alo's posture tells her end: stem leaning, leaves yellowing, pods browning; never a face (22 §2.5). |
| **Transition and chapter-ending hook** | Hook (curiosity and new objective): the last montage frame on 21 Oct settles on the descendant rack, where a few green stems stand among purple ones, and the map on the survey board. The saved May prediction blinks once in the journal. Bridge: the prediction card Mei carries into CH04-S01. |

### 2.4 Chapter 4 — *Into the Cold Trap* (`EX-CH04-S01`..`S12`, 21 Oct–12 Dec 2046, 90 min)

| Field | Revision |
|---|---|
| **Narrative and emotional development** | Canon arc: curiosity tested → caution recognised → field confidence → preserved discovery → personal anticipation. Revision: the split team is felt through sound: the rover's cabin hum and chassis vibration against Aurora's fans, joined by the clean local-radio click. Mei and Amara's base scenes are framed warm and close; the field is framed wide and hard-lit. |
| **Distinct gameplay challenge** | **Navigation and field measurement:** P-07 route choice, beacon placement and calibrated ice scan (S03–S05); P-08 careful recovery (S06–S10). 22 §6.1–§6.4. |
| **Mystery clue and payoff** | Canon: twelve specimens (S10), the lid inscription (S11), "I owe you the story" (S12). New `TEXT` (§4 clue 13): beside cotton on the vault manifest, in the same hand as the packet: "Cotton — sprouted in a sealed experiment on the Moon, 2019. Let one grow further. — N." It establishes that N. knew the real 2019 Chang'e-4 result and chose cotton on purpose. Payoff: CH05-S12 (cotton is the one planted) and CH08-S12 (Noor: "Show me the cotton by the window."). `STAGING` in S11: Ferreira's Earth feed shows her chair empty for the quiet moment; Rao speaks (canon line `EX-CH04-S11-L03`). |
| **Important choice and later consequence** | Beacon positions the player commits in S04 are saved and drawn as a faint older layer on the CH08 route map (§5; N1). Outcome: P-07 Golden (all beacons placed before blind corners). The prediction comparison in S01 closes the CH02 thread with the player's own reason shown. |
| **Learning objective** | Planning combines constraints instead of optimising one number (S03); a communication path must be tested (S04); controls and calibration separate a signal from an appearance (S05); an indication needs a functional test (S08). |
| **Visual and audio direction** | `SFX_ROVER_CABIN` and `SFX_ROVER_CHASSIS` (felt, never airborne); `CUE-06` layered only on verified stops, with its sting at S06 (CS-07); `SFX_SCANNER_BEEP`; headlights give hard light and black shadows; dust only moves when touched. |
| **Transition and chapter-ending hook** | Hook (personal anticipation): the fifth mug clipped above the table, Kai's line "We have a spare mug." (`EX-CH04-S12-L01`) and Ferreira's "I owe you the story." (`EX-CH04-S12-L03`). Bridge: the mug, which CH05-S01 opens on. |

### 2.5 Chapter 5 — *Shooting Stars* (`EX-CH05-S01`..`S12`, 12–15 Dec 2046, 85 min)

| Field | Revision |
|---|---|
| **Narrative and emotional development** | Canon arc: anticipation → discomfort → accountability → wonder → connection. Revision: the voice becomes a person (N5). Ferreira's first minutes are physical and small: she repeats the seal check, takes the corridor watch instead of a chair (canon), and stops for one second at the N.R. hatch cover on her watch (`STAGING`, S02). Mei's disagreement in S05 stays visible after the scene (§7.4). |
| **Distinct gameplay challenge** | **Historical investigation and observation:** P-09 chronology reconstruction (S03); P-10 impact-flash classification (S07); maintenance comparisons (S08). 22 §7.1–§7.4. |
| **Mystery clue and payoff** | Canon: four records (S03), confession (S05), signed page with consent (S10), text reply (S12). New `STAGING` bridge S02→S03: Ferreira unpacks a sealed document sleeve from her relief cargo and leaves it unopened on her locker shelf; on 14 Dec she brings it to the table. New `TEXT` on the evacuation order (§7.4): her own handwritten margin note. |
| **Important choice and later consequence** | `EX-CH05-S05-CHOICE` ("Why did you wait?" or "What came home?") decides which object Ferreira leaves on the table after the scene: the 2034 crew roster (accountability) or the drawer inventory (the seeds). It stays there through CH06 and is in the final photo (§5). `EX-CH05-S11-CHOICE` (invitation wording) returns in CH08-S10 as the message open on Mei's screen when Noor speaks. Outcome: the Dust Shield or Whipple upgrade at chapter end (canon; simulation applies it once). |
| **Learning objective** | Chronology and evidence (S03); plant life stages (S04); observation versus instrument artifacts (S07); causation needs its own evidence (S09); information provenance (S10). |
| **Visual and audio direction** | CS-08: lander dust falls straight down. CS-09: in-engine, static shared frame, **no music**, fans only (canon). Impact monitor: small flashes, no streaks. `CUE-07` starts only after the consent line (canon); `SFX_CONNECTOR`. Real observation added to the Data Card (§2.12): NASA recorded 45 lunar impact flashes during the 2015 Geminids, including 14–15 December, the same dates as this chapter. |
| **Transition and chapter-ending hook** | Hook (emotional question): cotton is planted in Tara's old bay; Kai is already marking the guide-light circuit for January's eclipse (canon). The player knows what Kai fears. Bridge: the strip of marker tape on the guide-light branch, which CH06-S01 opens beside. |

### 2.6 Chapter 6 — *The Red Ring* (`EX-CH06-S01`..`S12`, 12 Jan–14 Feb 2047, 85 min)

| Field | Revision |
|---|---|
| **Narrative and emotional development** | Canon arc: admission → preparation → shared wonder → interruption → supported action. Revision: the chosen companion (S01) stands at Kai's shoulder in S10 while the other speaks on the channel (`STAGING`); Ferreira stays in the doorway and does not take the task (canon "Ferreira remains nearby without taking over"). |
| **Distinct gameplay challenge** | **Energy budgeting for known darkness** (P-11, seven-unit teaching allocation) and **fault isolation** (P-12, rehearsal then the real F2 fault). 22 §8.1–§8.4. |
| **Mystery clue and payoff** | Canon: Noor's text "I watched a red ring from there once. — N." (`EX-CH06-S09-L01`), date left unspecified. `STAGING`: Ferreira reads it once and looks at her steel field watch; she does not explain. It keeps Expedition Zero's last days present without inventing a date. Payoff: CH07-S07 (the last sunset). |
| **Important choice and later consequence** | `EX-CH06-S01-CHOICE` (Rafi or Amara stays beside Kai) is a relationship choice: that person is beside Kai in S10, and in CH08-S01 that person clips the hand light to Kai's suit at the airlock (§5). `EX-CH06-S08-CHOICE` (ring diagram or protected-service plan sent home): the printout is pinned at Kai's bunk and travels in the rover in CH08. |
| **Learning objective** | Finite energy accounting (S03); trade-offs by controlled comparison (S04); fault isolation and redundancy (S05, S10); eclipse geometry and atmospheric light (S07); communication windows (S08); memory versus verified record (S09). |
| **Visual and audio direction** | `CUE-08` slow, receding under the feeder instructions (canon); `SFX_FAN_LOWPOWER`; `SFX_BREAKER_RESET`; amber guide light as the only warm source in the power room. The ring is seen only on the filtered camera monitor with the labelled Earth-limb diagram (CS-11). Real observation added (§2.12): Surveyor 3 photographed Earth eclipsing the Sun from the Moon on 24 April 1967, with sunlight refracted around Earth's atmosphere. |
| **Transition and chapter-ending hook** | Canon hook is a new warning. Vary it (`STAGING`): the montage ends quietly on the active-region image Rafi pinned in January; Rafi stands up from breakfast without a joke and opens the shared warning. The hook is the change in Rafi, not an alarm. |

### 2.7 Chapter 7 — *The Great Storm* (`EX-CH07-S01`..`S12`, 14 Feb–8 Apr 2047, 105 min)

| Field | Revision |
|---|---|
| **Narrative and emotional development** | Canon arc: shared warning → systems conflict → practised sheltering → meaning → bounded loss → prepared resolve. Revision: Ferreira moves her chair away from the head of the table (canon, S01) and answers her own roll call (S05); the lull (S07) is the quietest scene in the game; the silence after the storm (S09) is given a different texture from the CH01 silence (§2.11). |
| **Distinct gameplay challenge** | **Coordinated emergency response:** P-13 one integrated five-person plan, P-14 three waves, then diagnosis of the broken Earth uplink. 22 §9.1–§9.4. |
| **Mystery clue and payoff** | Canon: the last log explains Alo ("I'm calling the seeds Alo, light." `EX-CH07-S07-L01`) and the Academy's name. The chain is complete: packet → recordings → annex → vault → records → signed page → last log. `STAGING`: Mei places the log beside the packet, the signed page and the founder ledger (canon) and Ferreira closes her eyes when the last sunset is named. |
| **Important choice and later consequence** | Outcome: P-13 and P-14 mastery, earned upgrades applied once. Relationship: Kai's request "Keep the small guide light." and Mei's "It is already in the plan." (`EX-CH07-S12-L03`, `L04`) close the CH06 thread. |
| **Learning objective** | Counterfactual modelling (S01); changing boundary conditions (S02); event order in shared resources (S03–S04); verification of people and states (S05); localising faults by contrast (S09); networks and line of sight (S11). |
| **Visual and audio direction** | `CUE-09` low / mid / high stems by wave, silent in the lull and never over safety instructions (canon); radiation only on instruments; `SFX_HATCH_SEAL`. S09 "A Different Silence": local radio stays clean and close, while the Earth channel is held as dead air with no latency texture at all. |
| **Transition and chapter-ending hook** | Hook (new objective and separation): five names, two boards (S12), the rover bay door. Bridge: the duplicate checklists Mei and Kai exchange, which reappear in CH08-S01. |

### 2.8 Chapter 8 — *The Lighthouse* (`EX-CH08-S01`..`S12`, 8–10 Apr 2047, 120 min)

| Field | Revision |
|---|---|
| **Narrative and emotional development** | Canon arc: separation → known-road confidence → parallel responsibility → exact repair → chosen reunion → shared homecoming. Revision: Ferreira asks "Power isolated?" (`EX-CH08-S07-L01`) and lets Kai do the repair she could not in 2034 (`STAGING`: she braces the door, her hands never touch the controller). Rao's months of calling are shown when the Earth leg locks (§4 clue 20). |
| **Distinct gameplay challenge** | **Navigation, repair and communication across two teams:** P-15 two teams and one road, P-16 controller replacement, dual-link verification and ALO42. 22 §10.1–§10.4. |
| **Mystery clue and payoff** | Resolution: Noor's first live voice after both links pass (S10). The 2034 relay fault cause stays an honest blank on the Evidence board (CH05-S09 canon "The old fault needs its own evidence"), labelled "Not established". |
| **Important choice and later consequence** | `EX-CH08-S12-CHOICE` (dedication) is engraved on the lineage board and shown in the credits and the post-credits frame. The final photo gathers the echoes of `EX-CH01-S01`, `CH01-S04`, `CH03-S11`, `CH05-S05`, `CH05-S11` and `CH06-S01` (§7.6). Outcome: P-15/P-16 mastery (rover emergency reserve unused for Golden). |
| **Learning objective** | Whole-mission provisioning (S01); constraints over shortcuts (S02); navigation with independent references (S03); function versus appearance (S04); time-dependent demand (S05); freshness of information (S06); safe replacement (S07); end-to-end network reasoning (S08); signal versus data integrity (S09). |
| **Visual and audio direction** | `CUE-10` from cabin entry to the summit, fading for the repair (canon); the repair has no music, only checkbacks, `SFX_BATTERY_SWAP` and `SFX_CONTROLLER_POWERUP`; `CUE-11` after the verified voice lock; three ambiences joined by one radio channel (§7.5); `CUE-12` on the safe shutter open, with `SFX_SHUTTER_OPEN`, the same sound as CH01-S12. |
| **Transition and chapter-ending hook** | Completion, then the post-credits MARS drawer (§7.7). |

### 2.9 Scene-to-scene bridge list (no gaps)

For each join: what leaves the first scene and arrives in the next. **Kind:** O object, Q question, S sound, T task, L line, D dated time card, P place or person. **Holds** means canon already carries it (story-data.json prose or `transitionOut`); **Fix** names the proposed bridge for a weak join. There are 95 scene joins and 7 chapter joins. 96 of the 102 hold as written (three of those get a small optional touch); 6 get a fix, plus one new join from the credits to the post-credits still.

| Join | What carries over | Kind | Status |
|---|---|---|---|
| CH01 S01→S02 | Rafi turns the emergency card towards every seat; S02 opens on him placing four name tokens on the Safe Room board | O, T | Holds |
| CH01 S02→S03 | During the S02 roll call the inventory lamp on the dry-storage drawer blinks once in the background (a soft tick); after the bench check Mei goes to it, and S03 opens on the blink | S, O | **Fix** (07:00→10:00 had no cause) |
| CH01 S03→S04 | Two seeds, two cassettes, two destinations identified | O | Holds |
| CH01 S04→S05 | "Its unanswered initial can wait; the next care visit cannot." Kai's steady work light becomes the corridor switch | T, O | Holds |
| CH01 S05→S06 | The bud ("A bud is a useful result."); the date card to 25 Apr shows the player's latest bud photo, then the horizon display | O, D | Holds; the photo on the card is a small fix |
| CH01 S06→S07 | The acknowledged shared schedule on the table | T | Holds |
| CH01 S07→S08 | Shift 2 staged and paused before its drill | T | Holds |
| CH01 S08→S09 | The 18:00 date card; the masts approach sunset | D, T | Holds |
| CH01 S09→S10 | Low-power fan hum and the grey Earth-link button; the alarm tone breaks the quiet | S | Holds |
| CH01 S10→S11 | The alarm eases; the shelter wall is still full of borrowed water | O, T | Holds |
| CH01 S11→S12 | "Confirm opening the chamber's viewing shutter will be safe." | T | Holds |
| **CH01→CH02** | Tara's bud: the date card shows the player's photos of 27, 28 and 29 Apr; on 30 Apr the Earth console lights (`SFX_RADIO_EARTH_IN`) as Tara opens | O, S, D | **Fix** |
| CH02 S01→S02 | The protocol Mei opened; Tara's photo now beside Alo's | T, O | Holds |
| CH02 S02→S03 | The paper bee left on the bench; Kai's carrier latch | O | Holds |
| CH02 S03→S04 | The last practice boundary closes; both pressure indicators unchanged | T | Holds |
| CH02 S04→S05 | "A reason to keep caring tomorrow"; the saved contact image | T, O | Holds |
| CH02 S05→S06 | The seventh date card under the paired photographs | O, D | Holds |
| CH02 S06→S07 | The prediction thread drawn to the family-tree page; Kai brings a clean seed tray | O, Q | Holds |
| CH02 S07→S08 | The paper bee's wing exposes a matching equipment number | O | Holds |
| CH02 S08→S09 | Three source cards and a clean empty space where a person might belong | O, Q | Holds |
| CH02 S09→S10 | The playback button becomes available | T | Holds |
| CH02 S10→S11 | Mei: "Send the evidence." (`EX-CH02-S10-L04`) | L, T | Holds |
| CH02 S11→S12 | The cup beside the pending-reply indicator begins to tremble | O, S | Holds (the best join in the game) |
| **CH02→CH03** | No time jump: the same red pressure warning at 22:05 | S, T | Holds |
| CH03 S01→S02 | The independent gauge; Kai's guess filed under hypothesis | O, Q | Holds |
| CH03 S02→S03 | Three saved readings and the proposed boundary | T | Holds |
| CH03 S03→S04 | The approved sequence and rollback condition | T | Holds |
| CH03 S04→S05 | The seated clamp; Amara asks to leave the evidence visible | O | Holds |
| CH03 S05→S06 | Camera-only annex inspection granted; the service cover Kai saw move in CH02-S12 | O, Q | Holds |
| CH03 S06→S07 | The closed viewing port and the 8 May entry schedule | T, D | Holds |
| CH03 S07→S08 | The route sheet under a sealed cover | O | Holds |
| CH03 S08→S09 | Dated pod development 8–16 May | D, O | Holds |
| CH03 S09→S10 | The five-day dry-down becomes a vigil: one photo a day in the same frame (§7.3) | T, D | **Fix** |
| CH03 S10→S11 | 42 = 12 + 30 read on the bench; the pressed petal in its sleeve | O | Holds |
| CH03 S11→S12 | The petal placed where it can be seen; Tara's farewell opens S12 (proposed, §3.9) | O | Holds; Tara beat proposed |
| **CH03→CH04** | The saved May prediction; the map's preparation list; a few green stems among purple on the October rack (last montage frame) | O, Q | **Fix** (last frame) |
| CH04 S01→S02 | Rafi's question "what observation should they make next?"; the rover checklist | Q, T | Holds |
| CH04 S02→S03 | The hatch closes on two field and two home | T, P | Holds |
| CH04 S03→S04 | The ridge bends out of sight; the radio plan must bend with it | Q | Holds |
| CH04 S04→S05 | An unbroken chain home on the map | O | Holds |
| CH04 S05→S06 | The next sealed sample | T | Holds |
| CH04 S06→S07 | The carrier tethered beside the vault | O | Holds |
| CH04 S07→S08 | Probe, sleeve, cradle | T | Holds |
| CH04 S08→S09 | "The case is travelling home, not that the mystery has been solved." | L, O | Holds |
| CH04 S09→S10 | Mei's hand near the lid; the dry glovebox | O | Holds |
| CH04 S10→S11 | A line of handwriting under the lid | O, Q | Holds |
| CH04 S11→S12 | The saved inscription and its open question | Q | Holds |
| **CH04→CH05** | The fifth mug; the 8–12 Dec flight | O, D | Holds |
| CH05 S01→S02 | The five-person roster; her mug carried to the table | O | Holds |
| CH05 S02→S03 | Ferreira unpacks a sealed document sleeve from her cargo and leaves it on her shelf; on 14 Dec she brings it to the table | O, D | **Fix** (12→14 Dec had no cause) |
| CH05 S03→S04 | The photograph of frozen trays | O | Holds |
| CH05 S04→S05 | Mei's revised caption; Ferreira watching | O | Holds |
| CH05 S05→S06 | The disagreement kept visible; the object Ferreira left on the table (§5) | Q, O | Holds; object is a small fix |
| CH05 S06→S07 | The repair procedure opens without Earth; the observation clock | T | Holds |
| CH05 S07→S08 | The observation clock carried into maintenance | T | Holds |
| CH05 S08→S09 | The completed report | O | Holds |
| CH05 S09→S10 | Mei: "An initial leads us. A record finishes it." (`EX-CH05-S09-L04`); Rao's call brings a signed page | L, O | Holds |
| CH05 S10→S11 | The journal expands N. into Noor's full name | O | Holds |
| CH05 S11→S12 | Delivered; no immediate voice; a text the next day | Q, D | Holds |
| **CH05→CH06** | Kai's marker tape on the guide-light circuit | O | Holds |
| CH06 S01→S02 | The charged lamp clipped to Kai | O | Holds |
| CH06 S02→S03 | The guide-light branch on every segment | O | Holds |
| CH06 S03→S04 | The rehearsal forecast | T | Holds |
| CH06 S04→S05 | The labelled guide-light branch | O | Holds |
| CH06 S05→S06 | "A rehearsal pass does not sign the watch." (`EX-CH06-S05-L04`) | L, T | Holds |
| CH06 S06→S07 | Protected camera ready | T | Holds |
| CH06 S07→S08 | Kai: "Home helps us understand the dark." (`EX-CH06-S07-L03`) | L | Holds |
| CH06 S08→S09 | The open window; a text packet arrives | O | Holds |
| CH06 S09→S10 | Rafi saves the camera state locally | T | Holds (it foreshadows the drop) |
| CH06 S10→S11 | The camera image returns | T | Holds |
| CH06 S11→S12 | The lamp back in its clip | O | Holds |
| **CH06→CH07** | The active-region image Rafi pinned in January; he stands up from breakfast without a joke | O, P | **Fix** (vary the danger hook) |
| CH07 S01→S02 | The labelled source and the shared observations | T | Holds |
| CH07 S02→S03 | Five seat markers on the shelter diagram | O | Holds |
| CH07 S03→S04 | The return-water time in the plan | T | Holds |
| CH07 S04→S05 | The latched 15 + 15 seed case | O | Holds |
| CH07 S05→S06 | Both hatch indications agree | T | Holds |
| CH07 S06→S07 | The first wave ends; the lull | D | Holds |
| CH07 S07→S08 | "Four steps left" | T | Holds |
| CH07 S08→S09 | The final line on the chart; Rao does not answer | S | Holds |
| CH07 S09→S10 | The saved relay-bypass diagram | O | Holds |
| CH07 S10→S11 | The spare controller from December, Kai's note still clipped inside | O | Holds |
| CH07 S11→S12 | The packed equipment and the route | O | Holds |
| **CH07→CH08** | The duplicate checklists; 8 Apr 00:00 | O, D | Holds |
| CH08 S01→S02 | The travel clock starts | D | Holds |
| CH08 S02→S03 | Cruise begins on the surveyed road | T | Holds |
| CH08 S03→S04 | Brake set at the marker-two pad | T | Holds |
| CH08 S04→S05 | A time card holds the field position; control returns explicitly to Aurora | D, P | Holds |
| CH08 S05→S06 | The home forecast; the guide light exactly where it was planned | O | Holds |
| CH08 S06→S07 | The dark relay housing beyond the window | O | Holds |
| CH08 S07→S08 | The antenna panel wakes with two unverified channels | T | Holds |
| CH08 S08→S09 | Both legs locked | T | Holds |
| CH08 S09→S10 | The transmit button invites a human voice | O | Holds |
| CH08 S10→S11 | Rafi reads the return departure time | L, D | Holds |
| CH08 S11→S12 | Ferreira's mug beside the others; three hours to first light | O | Holds |
| **CH08→credits→CS-18** | The dedication the player chose, then the inventory lamp (§7.7) | O, S | **Fix** |

**Montage beat sheets (the four long intervals).** A montage is not a skip; each one is 4–6 dated interactive beats, each with one task and one human moment. All beats are `STAGING` or `TEXT` except the Tara beat.

| Montage | Dated beats (task · human moment) |
|---|---|
| CH03-S12, 21 May → 21 Oct 2046 | 31 May: Tara's farewell and harvest into the working stock (`[STORY CHANGE — needs Sadman's approval]`, §3.9) · June: first descendant flowers, pollinated with the same labelled brushes A and B · July: scheduled resupply unpacked; Kai hangs a second hand light "for guests" · August: Amara shows Kai how she reads the independent gauge · September: the next generation's seeds go to the working stock, never the founder 30 · 21 Oct: the rack, a few green stems, the map |
| CH04-S12, 22 Oct → 12 Dec 2046 | 23 Oct: the twelve-specimen report sent; Rao's receipt · November: Kai polishes the fifth mug once and is caught (canon CH05-S01 "Kai polished it once and denied doing so") · 1 Dec: the locker labelled · 8 Dec: departure notice on the Earth screen; Ferreira in a travel layer, not a uniform · 12 Dec: the landing camera |
| CH06-S12, 13 Jan → 14 Feb 2047 | Cotton's first true leaves in Tara's old bay · Rafi's watch handovers, each one shorter and calmer · a meal where Kai lets the corridor go dim on purpose · Noor's monthly "what grows next" photo strip (if chosen, §5) · 14 Feb breakfast |
| CH07-S10, 16 Feb → March 2047 | The crew keeps writing reports into an outbox labelled "Queued for Earth" that cannot send (`TEXT`; no reply ever arrives, canon) · cotton care · three maintenance gates (canon) · Ferreira teaches the cadets the relay controller housing at the fabrication bench. The queued outbox pays off in CH08-S09 when it finally sends (§4 clue 20). |

### 2.10 Gameplay that teaches: learning challenges, mistakes and failure

**The learning-challenge pattern.** Every challenge sits inside a practical task and runs **Predict → Act → See → Use it later**. No quizzes: the player commits a prediction on the same panel they will operate, the game shows the result next to the prediction, and a later chapter uses the same skill with one new constraint (22 §2.2 Reference Ladder). One signature challenge per chapter:

| Ch | Practical task | Objective | Player action | Feedback | Used again in |
|---|---|---|---|---|---|
| 1 | Route spare sunlight (S01); return borrowed water (S08, S11) | A full store cannot take more; a borrowed resource must go back | Predict where extra energy goes, then watch the overflow arrow; mark the water-return gate | The preview shows spill versus useful load; the water arrow returns along Kai's "return ticket" | CH07-S03/S04 (same water, five people) |
| 2 | Pollinate on the nonliving model, then the real flowers (S02, S04) | Pollination moves pollen; seeds come later | Match anthers and stigma, choose brush A or B by direction | A wrong placement on the model explains itself; on the real flower no seed shower appears | CH03-S09 (the seeds arrive, on their own schedule) |
| 3 | Three taps on one falling line (S02) | A hypothesis must fit every reading | Predict which tap falls before reading it | The board highlights the one reading a wrong location fails | CH05-S08 (two symptoms, two causes) |
| 4 | Dry reference before the bright patch (S05) | A signal needs a reference and a threshold | Record the dry reference, then compare three samples | Two positives, one kept negative control on the map | CH05-S07 (frames before and after a flash) |
| 5 | Reconstruct the 2034 order from four records (S03) | A condition is not the moment it became dangerous | Place records on a timeline by timestamp and signature | A wrong placement stays visible with the contradiction named | CH07-S09 (localise the failed branch by contrast) |
| 6 | Seven-unit eclipse plan (S03–S04) | Finite energy has to cover every segment | Predict the warning a missing package causes, then fix it | The segment that loses a service lights its own warning | CH08-S02 (14-unit rover budget with return reserve) |
| 7 | One plan from four good intentions (S03) | Event order decides whether shared water protects people or plants | Overlay four role plans and find the collision | The forecast shows which step each change affects | CH08-S05 (two at home, then five) |
| 8 | ALO42 (S09) | A strong signal is not correct data | Compare a near-match with the exact string | The near-match is rejected with its differing characters shown | The end-of-game debrief: "how we knew it worked" |

**Recoverable mistakes.** Every mistake below stops in a paused preview or an interlock, names the cause in a plain sentence (`TEXT`, shown with an icon, never colour alone), lets the player investigate the linked clue, and retries from the same step. Nothing is lost except, where 08 says so, a mastery star.

| Ch | Reasonable mistake | Specific feedback (`TEXT`) | Investigate | Retry path |
|---|---|---|---|---|
| 1 | Drain the shelter wall before the exposure it shields has resolved | "The wall is still shielding the next exposure. Drain after it resolves." | Open the exposure step on the forecast | Edit the staged shift; nothing was committed |
| 2 | One unlabelled brush for both directions | "With one brush you can't tell which pollen went where." | Compare the two plant records | Pick separately labelled tools |
| 3 | Isolate the habitat trunk | "This stops the leak and the habitat's air supply too." | Trace which services each boundary cuts | Choose the smallest supported boundary |
| 4 | Take the short route | "Route A is steeper than the rover's 15-degree limit." | Overlay the slope card | Choose route B; both limits must hold |
| 5 | Count a flash that never moves | "This point stays on the same detector pixel in every frame. That is the camera, not the Moon." | Step one frame back and forward | Reclassify it as an artifact |
| 6 | Reset all habitat power when F2 drops | "Essentials are holding. Only camera feeder F2 dropped." | Read the protected-service indicators | Isolate, verify and restore F2 only |
| 7 | Drain before the sixth exposure | "Exposure 6 has not been sampled yet." | Open step 6 on the chart | Hold water and cargo, then drain |
| 8 | Call the chain working when a marker lights | "Lit means powered. Test both neighbours." | Run the two adjacent-link tests | Continue only after both pass |

**Legitimate failure endings** stay where canon puts them (CH01 Alo Lost and Mission Stopped; `execution/ENDING_*.md`; M1-19). Every failure, in every chapter, closes with the same five-panel blame-free debrief (23 §7.4), written for a 10-year-old:

1. **What we planned** (the committed plan, in the player's own choices).
2. **What happened** (the readings that changed, step by step).
3. **Why** (one cause, linked to its Data Card; never "you were wrong").
4. **What we would change** (the one setting that matters, as a question).
5. **Try again from here** (the checkpoint, with its date and the state it restores).

For Alo Lost the screen also says, in plain text: "Alo did not survive the night in this attempt. Your checkpoint keeps her alive at the start of shift 5." The plant is never shown wilting on a loop; the closing image is the empty holder with her nameplate.

**Easy to pick up for everyone.** Rules for the first 15 minutes, all within 08 and the existing modes:

- **No way to fail before EX-CH01-S06.** S01–S05 choices are all safe (canon: "Both are safe commissioning choices").
- **One new verb per scene in Chapter 1:** S01 trace and route · S02 classify and roll call · S03 inspect and calibrate · S04 plant through glove ports · S05 care round and photograph · S06 arrange timeline cards · S07 preview and commit a shift.
- **A "What now?" button** on the HUD shows the current objective in one sentence and offers H1 (22 §2.3). It never solves.
- **Family Mode** (6+ with an adult): no timers, select → target → confirm for every drag, H1 offered after a rejected preview, Guided plans for P-02 and P-13 (22 §2.4). **Engineer Mode** adds real units and the formula behind each number. Story, endings and rewards are identical in all modes.
- **Short sessions:** scenes run 6–10 minutes and save at every exit gate, so a class can stop at the bell.

**Why it is fun.** Tactile verbs with weight (glove ports, brushes, clamps, a gauge needle that settles), visible consequences (the garden glows, the wall fills, a beacon's link indicator settles), "aha" deductions (22 §3–§10), a growing personal collection (the Growth Record photos, §3.8), and crew who react with their bodies (Kai sits back down, Amara's hand on a shoulder) rather than with barks.

### 2.11 Sound, music and silence

**Lunar sound rules** (15_AUDIO; ART_BIBLE §2 rule 7). Outside the hull there is no airborne sound. Allowed sources: the suit (breathing, fans, radio, the wearer's own voice), contact (boots on regolith, a tool on a housing, felt through the body), the pressurised rover cabin and chassis, and the habitat. Radio crosses vacuum; sound does not (NASA: sound waves cannot travel in the vacuum of space, [science.nasa.gov/ems/02_anatomy](https://science.nasa.gov/ems/02_anatomy/)).

**Four silences, four meanings.** The game uses silence as a vocabulary the player learns:

| Silence | Scene | What the player hears | What it means |
|---|---|---|---|
| Prepared silence | CH01-S09, after `SFX_RADIO_EARTH_LOST` | Low-power fans, the hand light's click | Earth is gone; the station and the crew are not |
| Respectful silence | CH03-S07 annex; CH03-S10 under the count | Suit breathing and local radio; then only `SFX_SEED_TICK` | Unfinished work and a finished life |
| Dead air | CH07-S09 | Clean local radio; the Earth channel held at zero, no latency texture | A broken path, not a broken crew |
| Working silence | CH08-S07 repair | Checkbacks, `SFX_BATTERY_SWAP`, `SFX_CONTROLLER_POWERUP` | Concentration; the music returns only when the link is proven |

The fifth silence is the **2.6-second round trip** in CH08-S10 (§7.5): one-way Earth–Moon radio delay is about 1.3 s (1.284–1.356 s in the Apollo 12 analysis, [nasa.gov ALSJ](https://www.nasa.gov/history/alsj/a12/A12Audio_Moon_Houston.html)).

**Cue transitions** (ids from `production/audio/music_cues.csv`): `CUE-01` → `CUE-02` crossfade on the first glove-port action (CH01-S04); `CUE-03` enters at the sunset gate and cuts to silence on `SFX_RADIO_EARTH_LOST`; `CUE-04` is a one-shot on the first petal, never restarted on re-read; `CUE-05` stops dead under the 42 count and returns at half level when the first descendant seed goes in; `CUE-06` layers only on verified stops; `CUE-07` waits for the consent line; `CUE-08` recedes under feeder instructions; `CUE-09` follows the wave state and is silent in the lull; `CUE-10` fades for the repair; `CUE-11` waits for the verified voice lock and gives Noor's first words 1.5 s of room; `CUE-12` starts on the safe shutter open. No cue ever plays over a safety instruction.

**New effects proposed** (`AUDIO`, ElevenLabs sound effects; add to `sfx_list.csv` with captions):

| Id | Description | Caption | First scene |
|---|---|---|---|
| `SFX_INVENTORY_LAMP_TICK` | A soft relay tick as the inventory lamp blinks | [inventory lamp] | CH01-S02 (background), S03, CS-18 |
| `SFX_EARTH_FIELD_MORNING` | Wind through a field, distant birds (Earth air, allowed) | [wind and birds] | Opening (§7.1) |
| `SFX_DHAKA_ROOFTOP_MORNING` | A city morning from a rooftop: distant traffic, birds, a kettle | [city morning] | CH08-S10 |

### 2.12 Science transparency: what is real, modelled, counterfactual or fiction

Every science item the player meets carries one of four labels, shown as a chip on Data Cards, journal entries and debrief panels (the catalog's `evidence_tag` and the fixture tags `[M]`/`[C]`/`[E]`/`[G]`/`[F]`):

| Label on screen | Meaning | Examples |
|---|---|---|
| **Real observation** | Measured or photographed by a real mission or experiment | LCROSS polar water evidence; Chang'e-4 cotton sprouting (2019); Surveyor 3 eclipse images (1967, new); 2015 Geminid impact flashes (new); STEREO-A 2012 measurements; MAVEN/RAD 2017 |
| **Model or reconstruction** | Computed from sources, or a teaching model of a real process | Polar illumination scenario; P-02 exposure score `Z`; route slopes; the eclipse viewing geometry (Computed-pending) |
| **What-if exercise** | A real event placed where it did not happen | CH07: the July 2012 CME as if it had hit the Moon |
| **Story (2046–2047)** | Fiction | Aurora, the crew, Alo, Tara, the 42 seeds, the annex, Noor, every date after today |

Two labelled replays stay exactly as canon: the **2017 historical replay** (CH01-S08/S10, "It is not a newly measured flare in 2046") and the **2012 counterfactual** (CH07-S01). Fictional future conditions are never shown with a "measured" chip.

**New claims used in this document, verified 4–5 Nov 2026:**

| Claim | Source | Assumption or boundary |
|---|---|---|
| Fast Plants flower in about two weeks; each stigma is receptive 2–4 days; pods mature about 20 days after pollination; plants come off water on the 20th day after the last pollination; seeds are harvestable about 40 days after planting | [Wisconsin Fast Plants FAQ](https://fastplants.org/frequently-asked-questions/) | Ideal Earth conditions; Aurora's dates are fiction (existing SRC-PLANTS boundary) |
| After seed ripening the parent plant senesces and dies; that is a normal life-cycle stage | [Fast Plants Life Cycle, stages I–J](https://www.fastplants.org/pdf/activities/FP_life_cycle.pdf); review of the end of flowering in Arabidopsis, [PMC10400124](https://pmc.ncbi.nlm.nih.gov/articles/PMC10400124/) | Supports "senescence is not a failure of care" |
| Genebanks keep a **base collection** for long-term conservation, not for use, and an **active collection** as working stock | [FAO/IPGRI Genebank Standards (1994)](https://www.fao.org/4/aj680e/aj680e.pdf); [Crop Genebank Knowledge Base](https://cropgenebank.sgrp.cgiar.org/index.php/procedures-mainmenu-243/conservation-mainmenu-198) | Real analogue for founder 30 (base) versus Tara's working stock (active), §3.9 |
| Earth–Moon one-way radio delay is about 1.3 s | [Apollo 12 audio analysis, nasa.gov ALSJ](https://www.nasa.gov/history/alsj/a12/A12Audio_Moon_Houston.html) | Relay processing would add a little; the pause is staged at 2.6 s round trip |
| Sound cannot travel in vacuum; radio can | [NASA Science, Anatomy of an Electromagnetic Wave](https://science.nasa.gov/ems/02_anatomy/) | |
| Surveyor 3 photographed Earth eclipsing the Sun from the Moon on 24 Apr 1967; Earth's atmosphere refracted sunlight around it | [NASA Science, APOD 7 Apr 2014](https://science.nasa.gov/image-article/apod-2014-april-7-a-solar-eclipse-from-the-moon/); [USGS, Television observations from Surveyor 3](https://pubs.usgs.gov/publication/70226796) | The 1967 images are grainy black-and-white; the red colour comes from SRC-ECLIPSE, not from Surveyor 3 |
| NASA detected 45 lunar impact flashes during the 2015 Geminids and analysed 30 from 14–15 December | Moser, Suggs & Ehlert 2017, [NTRS 20170004442](https://ntrs.nasa.gov/citations/20170004442) | CH05's 6 + 2 teaching set stays authored |
| The Chang'e-4 cotton seed germinated and grew a seedling on the Moon in 2019 | existing SRC-COTTON2019, [doi:10.3390/ijms222111723](https://doi.org/10.3390/ijms222111723) | The vault-manifest note (§4 clue 13) says only "sprouted"; nothing about flowering |
| Bangladesh Standard Time is UTC+6 with no daylight saving, so the CH08-S10 call (02:15–03:00 UTC) is 08:15–09:00 in Dhaka | [timeanddate.com](https://timeanddate.com/time/zone/bangladesh) | The rooftop is a morning scene; the Moon is **not** shown in Dhaka's sky unless its position is checked with JPL Horizons first |

---

## 3. Emotional arcs

Each arc lists motivation and fear, how they shape behaviour, one vulnerable moment, one contribution to another character's growth, and one later action that shows change. Screen time is proportional: the four cadets carry 332 of the 385 lines, Ferreira 40, Noor 5 plus N.'s 2, Rao 4. Backstory arrives through actions, short exchanges, records and optional text, never a speech. Existing development lines are in 04_CHARACTER_BIBLE; this section names the scenes that carry them and what is staged around them.

### 3.1 Kai — power and heat

| | |
|---|---|
| **Motivation / fear** | Wants to be the person who keeps a home running. Afraid of the dark, and of admitting a need in a technical team. |
| **Behaviour** | Reaches for switches first and jokes second ("Important scientific lamp." `EX-CH01-S05-L02`). Checks a switch twice early, a labelled plan once later (animation signature). |
| **Vulnerable moment** | CH06-S02: he opens his own childhood-storm memory and says "I did not know when it would return." (`EX-CH06-S02-L01`). He can stop the memory at any time (canon). |
| **Contribution to another** | His jokes make rules memorable for everyone ("I drew the water a return ticket." `EX-CH01-S08-L04`); his December compatibility note (CH05-S06) is what makes the CH08 repair possible; in CH03-S10 his "Do you want us to wait?" lets Mei ask the crew to stay. |
| **Later action showing change** | CH08-S03: he reaches for the steering control at the dark marker, stops, and brakes at the surveyed pad ("The crew's growth appears in that pause", canon). CH08-S04: "a small light and a known road" now describes infrastructure he repaired. Still afraid sometimes; reliable anyway (never "cured"). |
| **Staging added** | The hand light is his object (N2): marked home in CH01-S05, scratched in CH06-S01, clipped to his suit by his CH06 companion in CH08-S01 (§5), seen on the rover dash in CH08-S07. |

### 3.2 Amara — atmosphere and measurement

| | |
|---|---|
| **Motivation / fear** | Wants systems and promises to mean what they say. Afraid of making a confident claim that harms someone. |
| **Behaviour** | Exact numbers, short qualifications, deadpan humour ("A carefully inventoried spare mug." `EX-CH04-S12-L02`). Writes the blank labels before anyone can make a joke permanent (CH01-S03). |
| **Vulnerable moment** | CH03-S01: "The panel says tank. I do not trust the diagnosis yet." (`EX-CH03-S01-L01`), the first time she admits uncertainty aloud. |
| **Contribution to another** | Helps Mei accept that Alo is finishing, not failing ("It meant she could finish." `EX-CH03-S10-L02`); makes Kai's intuitions testable (CH03-S02). |
| **Later action showing change** | CH05-S02: she keeps her months-old corrected label visible when Ferreira asks why ("the old number was wrong"). CH08-S05: she repeats the independent gauge check calmly at home, the same check that once exposed the false leak. |
| **Staging added** | Her object is the independent gauge on its hook (CH03-S05 "leaves the independent gauge on its hook"); it is in the final photo's background. |

### 3.3 Mei — horticulture and living continuity

| | |
|---|---|
| **Motivation / fear** | Wants the garden to be a home, not a specimen cabinet. Afraid of failing a living thing that depends on her. |
| **Behaviour** | Talks to plants and people with the same direct care; notices what checklists miss (the four nameless mugs, CH01-S01; Tara's bud, CH01-S12). |
| **Vulnerable moment** | CH03-S10: "I thought keeping her alive meant longer." (`EX-CH03-S10-L01`). |
| **Contribution to another** | She asks Kai to read his action back in the storm ("Read this one back first." `EX-CH01-S10-L03`), turning panic into a team decision; she asks Ferreira the hard question in CH05-S05 ("You could have told us." `EX-CH05-S05-L02`), which lets Ferreira say what she was afraid of; she writes the invitation that brings Noor back (CH05-S11). |
| **Later action showing change** | CH08-S05: she keeps Aurora alive through the second long night with Amara, the same darkness that frightened them all in April ("Same darkness. Different garden." / "Different us." `EX-CH08-S05-L01`, `L02`). CH08-S12: she opens the shutter herself. |
| **Staging added** | Her pencil (ART_BIBLE §5) writes every Growth Record entry; in the final photo it rests on the lineage board. |

### 3.4 Rafi — safety and field operations

| | |
|---|---|
| **Motivation / fear** | Wants a warning heard before it becomes a rescue. Afraid of missing something, and of being "the person who always worries". |
| **Behaviour** | Checklists when focused, small jokes and noises when relaxed; cushions valid warnings with apologies early on. Quietly leaves the hand light "handle-out beside the locker" for Kai without making him explain (CH01-S05). |
| **Vulnerable moment** | CH04-S02: "I checked twice. Three times. I wanted to sound relaxed." (`EX-CH04-S02-L01`). |
| **Contribution to another** | Gives Kai the hand light and the habit of a checkback ("Rafi, stay on the channel." / "Here." CH06-S10); holds the camera steady so Mei sees the annex only when it is safe (CH03-S06). |
| **Later action showing change** | CH07-S01: he gives the storm warning with no joke and no apology ("New observations. Everyone needs them." `EX-CH07-S01-L01`). CH08-S11: his careful road brings everyone home. |
| **Staging added** | The paper bee is his object; it sits on the lineage board in the final garden. The CH06→CH07 hook is his posture: he stands up from breakfast without a joke (§2.6). |

### 3.5 Commander Ferreira — Expedition Zero's engineer

**Motivation:** finish a biologically meaningful expedition without letting pride override a retreat rule. **Fear:** another evacuation read as abandonment. **Regret:** she could not fix the radio in 2034, helped the gardener board and left living work behind, then avoided telling the story so long that discovery felt like secrecy (canon, CH05-S05). **Rule that never bends:** her regret never delays a safety instruction; every diagram arrives at once (CH03-S03 "Safety information does not wait.").

**Subtle signs before the confession** (timing of every revelation unchanged; none is a lie by omission about safety):

| # | Scene | Sign | Label | What a careful player can infer |
|---|---|---|---|---|
| F1 | CH01-S01 onward | On the Earth screen she wears a frayed gear-wheel engineering patch older than her commander tab (ART_BIBLE §5) | `ASSET` (exists) | She was an engineer before she commanded |
| F2 | CH01-S09 | Before the cutoff she waits for the read-back of "Local rules remain active. Read back the next safe action." (`EX-CH01-S09-L04`) and holds the channel one second after it, eyes on her steel field watch | `STAGING` | She has lost a link before, mid-instruction |
| F3 | CH02-S10 | The 2034 engineer's voice sounds like a younger her (canon); the board files it under Inferred | `DLG` | Possibly her; not proven |
| F4 | CH03-S03 | The repair diagram arrives immediately | `DLG` | Whatever she is hiding is not about safety |
| F5 | CH03-S06 | A one-second pause and a glance off-screen before "An isolated annex. Use the supplied boundary checks." | `STAGING` | The annex matters to her personally |
| F6 | CH03-S07 | The annex warm-side bench holds a tool tag with the same gear-wheel emblem as her patch | `ASSET` | An engineer with her emblem worked here |
| F7 | CH04-S02 | "Rafi leads the field team. Returning is part of the objective." (`EX-CH04-S02-L02`) | `DLG` | Returning matters to her more than finding |
| F8 | CH04-S11 | During the quiet moment her Earth feed shows her empty chair; Rao answers (`EX-CH04-S11-L03`) | `STAGING` | She cannot answer yet |
| F9 | CH04-S12 | "I owe you the story." | `DLG` | She has decided to tell it |
| F10 | CH05-S01 | "Ferreira. Seal indication checked twice." (`EX-CH05-S01-L02`): Kai's double-check, in her voice | `DLG` | She carries the same habit Kai does |
| F11 | CH05-S02 | On her first watch she stops for one second at the N.R. hatch cover, touches it, moves on; Amara sees it | `STAGING` | She knows that door |

**Behaviour change after the confession** (canon beats, with staging):

| Scene | Change |
|---|---|
| CH05-S05 | Sits level with the crew, hands resting away from the records (CS-09 static shared frame, no music). Leaves one record on the table after the scene, chosen by `EX-CH05-S05-CHOICE` (§5). |
| CH05-S06 | Leaves the personal identity page with Rao "for consented release later": she will not tell Noor's story for her. |
| CH05-S11 | Places her mug beside the four familiar ones: the first meal she sits down for. |
| CH06-S01, S10 | Waits in the doorway; stays nearby without taking over Kai's task (canon). |
| CH06-S09 | Reads Noor's eclipse note once, quietly, and looks at her watch (F2 returns). |
| CH07-S01 | Moves her chair away from the head of the table: "Your plan, cadets. I retain command responsibility." (`EX-CH07-S01-L03`). |
| CH07-S05 | Answers her own roll call like everyone else: "Ferreira here. Fifth position confirmed." |
| CH07-S10 montage | Teaches the cadets the relay controller housing at the fabrication bench (`STAGING`): the engineer passing on the repair she could not finish. |
| CH08-S07 | Asks "Power isolated?" and braces the service door; her hands never touch the controller. Kai repairs what she could not in 2034. |
| CH08-S10 | "You brought us the seeds." (`EX-CH08-S10-L03`): she gives the credit away. |
| CH08-S12 | "You did not just survive the Moon. You grew it." In the shared photo she stands at the edge until Mei pulls her into the frame (`STAGING`). |

### 3.6 Rao — the Earth desk

| | |
|---|---|
| **Motivation / fear** | Keep information moving without taking local agency away. Afraid of a crew feeling unsupported when the radio goes silent. |
| **Behaviour** | One practical observation at a time; friendly; covers for Ferreira without exposing her ("Manifest received. Your safety support is unchanged." `EX-CH04-S11-L03`). |
| **Vulnerable moment** | CH07-S09: Rao does not answer. The player never sees Rao during the blackout, which is the point. |
| **Contribution to another** | Handles Noor's consent before the reveal ("She gave permission to share the page." `EX-CH05-S10-L01`) so the cadets never have to pry. |
| **Later action showing change** | CH08-S09/S10: when the Earth leg locks, Rao's **listening log** arrives with the backlog (`TEXT`, §4 clue 20): one short timestamped line every few hours for 52 days, "Aurora, Earth. Listening." Then Rao "leaves room on the channel" (canon prose) instead of talking. |

### 3.7 Dr Noor Rahman — the gardener N.

| | |
|---|---|
| **Motivation / fear** | Let the living work continue without making young colleagues carry her disappointment. Afraid of becoming the symbol of another failed garden. |
| **Behaviour** | Present only through things she left (packet, recordings, annex, vault, manifest notes) and, after consent, through text she chooses to send. She never watches the crew: she reads only transmitted reports (canon CH05-S10). |
| **Vulnerable moment** | CH07-S07, the historical last log from the departure day: the name Alo, and the last sunset she saw on the Moon. |
| **Contribution to another** | Becomes Mei's mentor by consent; her reply "Thank you for asking. I would like to see what you grow next." (`EX-CH05-S12-L01`) gives Mei's care a person to report to. |
| **Later action showing change** | CH08-S10: she chooses to speak live for the first time ("Hello, Aurora. This is Noor."). CH08-S12: her first request in the whole game, "Show me the cotton by the window.", asks for the plant she chose in 2034 (§4 clue 13). |

### 3.8 Alo — the first plant (no face, no speech)

Attachment comes from **repeated, varied care** the player performs and records, and from the crew's reactions (§7.2). Alo's personality is posture only: lean towards light, droop when thirsty, cupped leaves in cold, upright after care, the flower opening at the bloom beat (ART_BIBLE §6). Senescence is shown as natural from the first day: the Growth Record (journal Garden tab, §6) shows the whole life-cycle track with Alo's marker moving along it, and the far end is labelled "seeds" from 11 April. Her death is never a surprise and never a failure.

**Alo's dated growth record** (dates from `plant_service.gd` and campaign_rules.json; stage descriptions from the [Fast Plants life cycle](https://www.fastplants.org/pdf/activities/FP_life_cycle.pdf)):

| Date (day) | Code stage | What the player sees | Player action | Art |
|---|---|---|---|---|
| 11 Apr 2046 (0) | `seed` | Seed in the cassette, label ALO | Plant through glove ports (CH01-S04) | exists (cassette) |
| 12–13 Apr (1–2) | `sprout` | Hooked stem, then two heart-shaped seed leaves (cotyledons) | First Care Round photo | **new** cotyledon state |
| 15–17 Apr (4–6) | `sprout` | First rough-edged true leaves above the cotyledons | Care Round | **new** true-leaf state |
| 18 Apr (7) | `bud` | Tight green bud cluster at the tip | Photo; Amara: "A bud is a useful result." | exists (Alo_Bud) |
| 25–27 Apr (14–16) | `bud` under P-02 | Posture reads the night: leaves cup in COOL, droop when thirsty, recover after return water | The P-02 plan | blend shapes (exists) |
| 27 Apr (16) | `bloom` | Four yellow petals in a cross | Tag the bloom photo → N.'s recording (CH01-S12) | exists (Alo_Bloom) |
| 30 Apr, 3 May, 6 May (19, 22, 25) | `pollinated` | Open flowers; one brush contact each run; no instant seeds | Three reciprocal runs (CH02) | exists |
| 8 May (27) | `pod_bearing` | Slender green pods lengthening below fading flowers | Pod observation photo | exists (Alo_Pods) |
| 16 May (35) | `mature_pods` | Pods swollen and straw-coloured; lower leaves yellowing; stem leaning | Approve the dry-down (CH03-S09) | **new** senescent variant |
| 16–21 May (35–40) | `mature_dry` | Leaves brown and dry, pods brittle, a petal fallen against the wall | Vigil: one photo a day (§7.3) | **new** dry variant |
| 21 May (40) | `archived_petal` | Pressed petal in its sleeve; the empty cassette cleaned and reused as position 1 of the twelve | Open pods, count 42 = 12 + 30, sleeve the petal | exists (PressedPetal) |

### 3.9 Tara — partner, reference and lineage (no face, no speech)

Canon makes Tara Alo's equal partner and the indoor reference plant (CH01-S04 "A reference is a plant we care for, not one we ignore."), and the reciprocal runs pollinated Tara too (CH02-S04). **Canon does not say what happened to Tara or her pods.** The code ends her quietly on 22 May with no harvest (C1).

**Proposed resolution** `[STORY CHANGE — needs Sadman's approval]` (no new spoken line; the numeric contracts and the 42 = 12 + 30 ledger are untouched):

1. **Tara finishes later than Alo, for a reason the player can read.** Her pods develop in the cooler indoor reference bay. Following the Fast Plants rule "take plants off water on the 20th day after your last pollination", her watering stops on **26 May 2046** (20 days after the 6 May run), the dry-down runs five days like Alo's, and her harvest is **31 May 2046** (day 50). The paired conditions in the Growth Record (CH01-S04 choice) show the temperature difference, so "a comparison retains its conditions" pays off (`EX-CH01-S04` learning).
2. **Her seeds become the working stock.** The reciprocal cross makes Tara the seed parent of her own line, recorded as **Tara × Alo** beside the founders' **Alo × Tara**. Her seeds are sealed as the garden's working stock for later generations, recorded without a headline count (character bible: "without inventing a second fixed seed count or mixing it with the founder ledger"). This mirrors real genebank practice: a protected **base collection** that is not used (the founder 30) and an **active collection** that is ([FAO/IPGRI Genebank Standards](https://www.fao.org/4/aj680e/aj680e.pdf)). Plain-language line in the journal: "Tara's seeds are the ones we use, so Alo's thirty can stay sealed."
3. **Her farewell is the first beat of CH03-S12 (31 May).** All four cadets are present; the player takes Tara's last photo in her own frame, removes her nameplate from the holder (the one Mei pressed on in CH01-S04) and places it on the lineage board beside Alo's petal. `CUE-02` at low level; no new line (§7.6).
4. **Her bay becomes cotton's bay.** Cotton is planted "in the indoor reference bay" on 15 Dec (CH05-S12, canon). Mei leaves Tara's name on the bay frame. In the final garden, "the cotton by the window" grows in Tara's bay with her name beneath it (§7.6).
5. **Code:** Tara gets `mature_days` 45 and a harvest into a working-stock ledger instead of `naturally_dead` with zero yield; her archived state is `archived_nameplate` (parallel to Alo's `archived_petal`). Board task `M3-96`.

**Compatible alternative if Sadman declines a dated harvest:** keep the code's 22 May natural end, add no harvest, and stage only beats 3 and 4 (the nameplate on the lineage board and her name on cotton's bay). The lineage still reads Alo × Tara.

---

## 4. Noor clue-and-reveal timeline

**Reveal rules (unchanged canon):** N. stays anonymous through CH04; the voice resemblance is an inference, never proof; no death, disappearance or betrayal is ever implied; nobody withholds safety information; Noor's identity is shared only with her consent in CH05-S10; she reads only transmitted reports; her first live voice is CH08-S10, after both relay legs are verified. CH08-S10 is the **arrival of a person the player knows**, not a second reveal.

**Clue kinds:** `OBJ` object · `LOG` record or recording · `DLG` existing canon line · `STAGING` a reaction or a pause · `TEXT` new written world text (never spoken). Rows marked **NEW** are proposals; the rest are canon.

| # | Scene | Clue (kind) | Where it is found | What it establishes | Reasonable inference | Still unanswered | Pays off in |
|---|---|---|---|---|---|---|---|
| 1 | CH01-S03 | The packet: ALO and N. in Latin letters (`OBJ`) | Dry-storage drawer | Someone named the seeds before the crew arrived | N. cared about these seeds and about light | Who N. is; why two seeds | CH05-S10; CH07-S07 |
| 2 | CH01-S03 **NEW** | Inside the drawer lid, in pencil: "Seed 1: outer chamber. Seed 2: inside, for comparison. Water at" — the line stops (`TEXT`) | Drawer lid, seen with the inspection camera | N. planned this exact two-place experiment | The plan was interrupted | Why it stopped | CH03-S07 (interrupted trial); CH05-S05 (the seed drawer in the final minutes) |
| 3 | CH01-S12 | N.'s stored recording, triggered by tagging the bloom photo (`LOG`) | Chamber shutter | N. expected a future bloom and left a message for it | N. hoped another crew would come | When it was recorded | CH07-S07 (the same voice on the departure day) |
| 4 | CH02-S07 | The recorder's equipment number matches an old trial card (`OBJ`) | Recorder service label | The crew's recorder belonged to an earlier trial | Their ordinary tools have a history | Which trial, whose | CH02-S08, S09 |
| 5 | CH02-S08 | Label under a label: serial plate, maintenance date, a chart saying the reproductive stage was not reached (`OBJ`) | Recorder | An earlier trial stopped before flowering | Alo's bloom is still a first | Who ran it | CH03-S07; CH05-S04 |
| 6 | CH02-S09 | The reconstructed 2034 file: date, device, two voice channels (`LOG`) | Evidence board | An engineer and a gardener worked together in 2034 | Two people, two roles | Their names | CH02-S10 |
| 7 | CH02-S10 | Engineer: "Biological trial suspended. Crew retreat is mandatory." (`EX-CH02-S10-L01`) | Playback station | A safe retreat was ordered | The voice resembles a younger Ferreira (filed under Inferred) | Is it her? | CH05-S05 |
| 8 | CH02-S10 | N.: "My grandmother’s mustard fields turned yellow every winter. I wanted some of that light here." (`EX-CH02-S10-L03`), over a two-second hold on the opening field (`STAGING`, §7.1) | Playback station | N. is connected to Bangladesh and to yellow mustard | The field in the opening was hers to remember | Her identity | CH05-S10; CH08-S10 rooftop |
| 9 | CH02-S11 | The pending-reply indicator after the package goes to Ferreira (`OBJ`) | Earth console | Ferreira has the evidence | She has not answered | Why | CH04-S12; CH05-S05 |
| 10 | CH03-S06 | The service hatch marked N.R. (`OBJ`) and Ferreira's one-second pause before "An isolated annex. Use the supplied boundary checks." (`STAGING`) | Floor under the displaced cover | The annex was N.'s; it matters to Ferreira | N.R. is the gardener | The full name; Ferreira's link | CH05-S05; CH05-S10 |
| 11 | CH03-S07 | Frozen, unflowered seedlings; a 2034 service tag; a route sheet filed before the evacuation (`OBJ`) | Cold annex | The trial was interrupted by an evacuation | The cold came after people left | What happened to the people | CH05-S03 |
| 12 | CH03-S07 **NEW** | The growth chart's last handwritten line stops at "Day 12. Leaves curling. Heat" (`TEXT`); a tool tag on the warm-side bench carries the gear-wheel emblem from Ferreira's old patch (`ASSET`) | Cold annex | The record ends mid-observation; an engineer with that emblem worked here | Ferreira may have been here (consistent with clue 7) | Her role | CH05-S03; CH05-S05 |
| 13 | CH03-S08 | The map: a storage deposit dated before the retreat (`OBJ`) | Annex chart archive | The vault was placed on purpose, on an earlier survey | N. planned for a later crew | What is inside | CH04-S06; CH04-S10 |
| 14 | CH04-S10 **NEW** | Twelve specimens, including cotton (canon). Beside cotton on the manifest, in the packet's hand: "Cotton sprouted in a sealed experiment on the Moon in 2019. Let one grow further. — N." (`TEXT`) | Glovebox scan | N. chose cotton on purpose, knowing the real 2019 result | She hoped a later crew would take it further | Will it grow? | CH05-S12 (cotton is the one planted); CH08-S12 ("Show me the cotton by the window.") |
| 15 | CH04-S11 | The lid: "ask Commander Ferreira about Expedition Zero" (`OBJ`); her Earth feed shows an empty chair while Rao answers (`STAGING`) | Glovebox; Earth console | Ferreira is the person to ask | She has a hard connection to it | What she will say | CH04-S12; CH05-S05 |
| 16 | CH04-S12 | Ferreira: "I owe you the story." (`EX-CH04-S12-L03`) | Earth link | She will tell it in person | | | CH05-S05 |
| 17 | CH05-S03 | Four records: relay fault report, greenhouse service note, evacuation order, ascent manifest. Every name has a boarding mark (`LOG`) | Mission table | Everyone came home | "The garden was left. The gardener was not." (`EX-CH05-S03-L04`) | N.'s identity | CH05-S10 |
| 18 | CH05-S05 | "I was the engineer who could not fix the radio." (`EX-CH05-S05-L01`) and, **NEW**, her margin note on the evacuation order: "Radio not restored. Retreat ordered. Garden left on minimum heat. I told her someone would come back for it. — Ferreira" (`TEXT`) | On the back of the evacuation order, which Ferreira turns over only after her confession (so the CH05-S05 timing is unchanged) | Ferreira's role, her promise and her regret | Noor was "her" | Noor's name (Ferreira waits for consent) | CH05-S10 |
| 19 | CH05-S10 | The signed page, with permission: Dr Noor Rahman, botanist, returned to Bangladesh, founded Last Light Academy; she read every report that reached Earth (`LOG`, `DLG`) | Live Earth link | Identity, survival, founder role | She has followed quietly through reports only | Will she speak to us? | CH05-S12; CH08-S10 |
| 20 | CH05-S12, CH06-S09 | Her texts: "Thank you for asking…"; "I watched a red ring from there once. — N." (`DLG` as text) | Message log | She answers by choice, in writing; she was on the Moon during an eclipse | | When (left unspecified, canon) | CH07-S07; CH08-S10 |
| 21 | CH07-S07 | The last log: "I'm calling the seeds Alo, light."; the Academy named after the last sunset (`LOG`) | Safe Room archive | The name and the Academy's origin | The chain is complete | Will we hear her live? | CH08-S10 |
| 22 | CH08-S09 **NEW** | When the Earth leg locks, two backlogs cross: Aurora's "Queued for Earth" outbox from the blackout finally sends, and Rao's listening log arrives, one line every few hours for 52 days: "Aurora, Earth. Listening." (`TEXT`) | Relay data panel and Aurora's console | Earth never stopped calling; Noor now receives the reports from the silent weeks | | | CH08-S10 |
| 23 | CH08-S10 | "Hello, Aurora. This is Noor." (`EX-CH08-S10-L01`) | The three-place call | A person the player knows arrives, by her own choice | | | CH08-S12 |

Clue 18's note is `[STORY CHANGE — needs Sadman's approval]` because it adds Ferreira's promise as a story fact; it fits CH05-S05's prose ("a gardener who believed another crew would come"). Clue 22's 52 days run from the CH07-S09 failure on 16 Feb to the relay lock on 9 Apr 2047 (dates from canon).

**Open-questions ledger** (the journal's Unknown column, §6). Each question opens in one place, gets partial answers and closes in one place, so the player is always holding two or three live questions and never more than five.

| Question | Opens | Partial answers | Closes |
|---|---|---|---|
| Who is N.? | CH01-S03 | CH02-S10 (Bangladesh, mustard fields), CH03-S06 (N.R.) | CH05-S10 |
| Why two seeds in a drawer? | CH01-S03 | Clue 2 (the plan), CH03-S07 (the interruption), CH03-S08 (the vault) | CH05-S05 |
| Did an earlier garden flower? | CH02-S08 | CH03-S07 (seedlings only) | CH05-S04 ("Then Alo finished a step they could not.") |
| Whose is the engineer's voice? | CH02-S10 | Clues 10, 12, 15 | CH05-S05 |
| Did everyone come home? | CH03-S07 | CH04-S11 | CH05-S03 (every name boarded) |
| What is in the vault? | CH03-S08 | CH04-S06 | CH04-S10 |
| Why cotton? | CH04-S10 | CH05-S12 | CH08-S12 |
| Does she want to hear from us? | CH05-S06 | CH05-S12, CH06-S09 (texts) | CH08-S10 |
| Why "Alo"; why "Last Light"? | CH01-S03 ("Alo means light.") | CH02-S10 | CH07-S07 |
| What caused the 2034 relay fault? | CH05-S03 | CH05-S09 (an honest blank) | Stays "Not established": the one deliberate open record, shown as such |
| When did Noor see the red ring? | CH06-S09 | — | Stays unspecified (canon) |
| What is in the MARS drawer? | CS-18 | — | Open by design (§7.7) |

---

## 5. Decision-consequence map

### 5.1 Four kinds of choice

| Kind | What it changes | Examples | Where it is stored |
|---|---|---|---|
| **Outcome-changing** | The result and the numbers, inside existing systems | P-02 endings (Golden Bloom, Bloom, Alo Lost, Mission Stopped); each chapter's earned upgrade pair (e.g. Dust Shield or Whipple after CH05); mastery stars and Golden criteria (10_GAMEPLAY_SYSTEMS) | `resources`, `upgrades.choices`, mastery profile (all exist) |
| **Preparation** | What the crew has ready later: a format, a photo, a placed beacon | `EX-CH01-S01`, `EX-CH01-S04`, CH04 beacon positions | `story_log.choices` (new), route receipts (exist) |
| **Interpretation** | How the record reads: a prediction, a classification, a dedication | `EX-CH02-S06`, `EX-CH02-S10`, CH03-S11 dedication, `EX-CH08-S12` | `story_log.choices` |
| **Relationship** | Who stands beside whom; which object a person leaves; how a message was worded | `EX-CH05-S05`, `EX-CH05-S11`, `EX-CH06-S01`, `EX-CH06-S08` | `story_log.choices` |

**Crew safety stays highest.** No choice can trade a person for a resource (CH01-S02 "These are names. We do not spend them."). Unsafe options stay in paused preview, as canon already does.

**Branches reconnect at the next exit gate, every time.** A branch may change only (a) whether an object is present and where, (b) a journal entry, (c) which photo or written text is shown, and (d) who stands where. It never changes a spoken line, a number, a puzzle contract or a knowledge flag. That keeps 96 scenes, 385 recorded lines and 08 intact while the player sees their own choices return.

### 5.2 The map

| # | Choice (catalog id) | Options and the evidence the player has | Immediate consequence | Persistent state | Later scene affected | How the player recognises the link | How branches reconnect |
|---|---|---|---|---|---|---|---|
| D1 | `EX-CH01-S01-CHOICE` Where should spare energy go? (preparation) | `OPT01` Store air / `OPT02` Light the planting bay; the overflow preview | Air gauge rises / the empty garden glows (canon) | `story_log.choices`; an automatic "Day one" photo of the gauge or the glowing bench | CH08-S05: the framed Day-one photo hangs beside the home console; CH08-S12 final photo board | The same image, dated 11 Apr 2046, beside the second long night | Both reach the fixed 25 Apr P-02 baseline (canon) |
| D2 | `EX-CH01-S04-CHOICE` How is the notebook organised? (preparation) | `OPT01` Paired photographs / `OPT02` Paired conditions table | The Growth Record opens in that layout | `story_log.choices` | Growth Record layout everywhere: CH03-S09/S10 maturity view, CH04-S01 comparison, CH03-S12 Tara's later finish (§3.9), final photo | "My notebook" looks the way they set it up; the other view is one tap away | Both layouts hold the same dated data |
| D3 | P-02 response and ending (`EX-CH01-S10`, `S11`) (outcome) | WAIT / PUMP / STACK as the forecast allows (08) | Golden Bloom, Bloom, Alo Lost or Mission Stopped | `resources`, mastery profile | Debrief (M1-19); CH01 postcard; mastery stars | Shift-by-shift replay before the debrief | Bloom and Golden Bloom continue; losses retry from the checkpoint (canon) |
| D4 | `EX-CH02-S06-CHOICE` Stem-colour prediction (interpretation) | `OPT01` Both colours may appear / `OPT02` Evidence insufficient; written reason and a surprise criterion | Dated prediction saved | Prediction record (canon) | CH04-S01: the October count shown beside the player's own reason | Their sentence from May, in their words | Both are compared honestly; no ratio is promised (canon) |
| D5 | `EX-CH02-S10-CHOICE` How is the familiar voice classified? (interpretation) | `OPT01` Proof / `OPT02` Inference | The board files it; the proof option is corrected in preview | `story_log.choices` | CH05-S03: the card reads "Kept as an inference since 6 May" (`OPT02`) or "Corrected to an inference on 6 May" (`OPT01`) (`TEXT`) | The Evidence board remembers how they first handled it | Same evidence package either way (canon) |
| D6 | CH03-S11 dedication, new id `EX-CH03-S11-DEDICATION` (interpretation) | "Light and Star" / "For Alo and Tara" / "The Next Small Thing" (`TEXT`) | The tray card carries the words | `story_log.choices` | CH04-S01 rack label; CH08-S12 lineage board; credits | Their words on the rack, months later | Quantities never change (canon) |
| D7 | CH04 beacon positions (P-07) (preparation) | Supported mounts at each blind corner | The link indicator settles beside each name | Route receipts (exist) | CH08-S02 route map: the October ridge beacons drawn as a faint older layer | "That's where we put the first ones" | No gameplay effect on P-15 |
| D8 | Chapter upgrade choice, e.g. Dust Shield or Whipple after CH05 (outcome) | The earned pair (canon) | Modifier applied once by the simulation | `upgrades.choices` (exists) | Later P-xx numbers (M3-91, 128 profiles) | The upgrade is visible on the hardware | Every combination has a safe main path (10_GAMEPLAY_SYSTEMS) |
| D9 | `EX-CH05-S05-CHOICE` What should Mei ask first? (relationship) | `OPT01` "Why did you wait?" / `OPT02` "What came home?" | Both facts are acknowledged (canon) | `story_log.choices` | After S05, Ferreira leaves one 2034 record at her place: the **ascent manifest** (`OPT01`: what she did right and what she avoided saying) or the **greenhouse service note** (`OPT02`: the garden left behind). It stays there through CH06–CH07 and is in the final photo | The object at her place, every time the table is on screen | All safety information stays available (canon) |
| D10 | `EX-CH05-S11-CHOICE` How should the invitation begin? (relationship) | `OPT01` "Would you like to see what grows next?" / `OPT02` "We kept a place for your work." | Delivered once (canon) | `story_log.choices` | `OPT01`: Mei sends Noor a dated "What grows next" photo strip each month (CH06-S12; queued in CH07-S10). `OPT02`: a seed-label holder marked "N." sits at the table from CH05-S11 on. CH08-S10: the sent invitation is open on Mei's screen when Noor speaks, and Mei's "We kept a place for you." either echoes her own words or names what she did | Her own message on screen at the moment of the call | Noor's replies and lines are identical (canon) |
| D11 | `EX-CH06-S01-CHOICE` Who stays beside Kai? (relationship) | `OPT01` Rafi / `OPT02` Amara | Companion assigned (canon) | `story_log.choices` | CH06-S10: that person is at Kai's shoulder, the other on the channel. CH08-S01: that person clips the hand light to Kai's suit (Amara at the airlock before he boards, or Rafi inside the cabin) | The same person, the same lamp, a year later | Lines unchanged; Rafi still answers "Here." on the channel |
| D12 | `EX-CH06-S08-CHOICE` Which observation goes home? (relationship) | `OPT01` Ring diagram / `OPT02` Protected-service plan | Delivered or buffered (canon) | `story_log.choices` | The printout pinned at Kai's bunk; it rides on the rover dash in CH08-S03/S07 | His family's copy, travelling with him | Same qualifications either way |
| D13 | `EX-CH08-S12-CHOICE` Which dedication fits? (interpretation) | `OPT01` "For every hand that kept the light" / `OPT02` "For the gardens we leave for others" | Photo and credits complete | `story_log.choices` | Lineage-board plaque; credits; the edge of the CS-18 still (§7.7) | Their words under the garden, and again after the credits | No task gates the ending (canon) |

**Optional moments** (staged interactions, no choice): `CH01-MUGS-NAMED` (S12), `CH03-ALO-VIGIL-1`..`5` (16–21 May photos), `CH03-TARA-FAREWELL` (31 May, if approved), `CH05-HATCH-PAUSE` (Ferreira at the hatch), `CH08-LIGHT-CLIPPED`. Each is stored once in `story_log.moments`, shown in the journal's People or Garden tab, and never gates progress.

### 5.3 Cross-chapter examples, as the player lives them

- **The notebook (D2 → CH03 → CH08).** On day one the player chooses photographs. Forty days later, on the dry-down screen, Alo's first photo from 12 April sits beside today's, in the layout they chose. In April 2047 the final photo is pinned beside that same strip.
- **The question (D9 → CH06 → CH08).** The player asks "What came home?". The greenhouse service note stays at Ferreira's place. In CH06-S01 it is under her mug in the background; in CH08-S12 it is propped against the lineage board beside Alo's petal: the garden she left, beside the garden they grew.
- **The invitation (D10 → CH06 → CH08).** "We kept a place for your work." A small holder marked "N." waits at the table for four months. When Noor speaks live and Mei says "We kept a place for you.", the camera finds the holder.
- **The companion (D11 → CH08).** Amara sat with Kai in January. In April she stays home, but before the airlock seals she clips the hand light to his suit and steps back.

### 5.4 Save and campaign state mapping

Today `CampaignState.new_snapshot()` (schema 2) has no choice store, and `SaveService.migrate()` handles only v1 → v2. Proposal (`CODE`, board `M1-47`), smallest change that works:

```gdscript
# campaign_state.gd, new_snapshot(): one new key; SCHEMA_VERSION 2 -> 3
"story_log": {
	"choices": {},  # choice_id -> {"option_id", "scene_id", "scenario_datetime", "state_revision"}
	"moments": [],  # ordered unique moment ids, e.g. "CH01-MUGS-NAMED"
},
```

- **Migration:** `SaveService.migrate()` gains `_migrate_v2()` that copies a v2 snapshot and adds an empty `story_log`. Existing saves keep working.
- **Validation:** `story_log.choices` is a Dictionary of Dictionaries whose `option_id` exists in the catalog's `choice.options` for that `choice_id` (or in the small list of new ids such as `EX-CH03-S11-DEDICATION`); `moments` is an Array of unique Strings.
- **Commands:** two new director verbs, committed like every other command (receipt, revision, idempotent by `command_id`): `record_choice {choice_id, option_id}` when a decision review is **confirmed** (previews stay free and unrecorded), and `record_moment {moment_id}`. A choice locks when its scene's exit gate passes.
- **Photos:** no new storage. A Growth Record photo is a plant care entry with `care_id` `"photo"`; `PlantService.apply_care()` already keys receipts by `care@date`, which gives exactly one photo per plant per day.
- **Echoes:** a data file `game/resources/campaign/content/story_echoes.json` maps `choice_id`/`option_id` or `moment_id` → `{scene_id, kind: object|journal|photo|staging, target_id, text}`. One pure function returns the echoes for a scene from the snapshot. Rooms and the journal read it; nothing else changes. Data-driven, testable without the scene tree.

---

## 6. Mission journal specification

Builds on SYS-07 (10_GAMEPLAY_SYSTEMS), the UI_07 screen contract (left tabs, dated middle list, right detail with source and objective link) and 22's Evidence board (T1, T2). It replaces nothing in those documents; it fixes the content model, the update triggers, the spoiler rules and the resume summary, and maps each to the code that exists today.

### 6.1 What exists in code

| Part | File | Today |
|---|---|---|
| Journal data | `game/scripts/dialogue/knowledge_service.gd` `CampaignKnowledge.journal(snapshot)` | Returns acquired-evidence records (title, evidence label, observation labels), newest first, plus two training references |
| Evidence grant | same file, `grant_operation()` | On a committed operation, adds the scene record and one observation; masks labels containing "noor" until `noor_identity_revealed`; grants `knowledge_reveals` on the scene's last target |
| Panel | `game/scripts/ui/campaign_panels.gd` panel `journal_discovery`, `_render_journal()` | One column of cards; "Acquired evidence only; unrevealed knowledge stays hidden." |
| Entry point | `game/scripts/ui/chapter1_campaign_hud.gd` JOURNAL button; `chapter1_campaign.gd:170` puts `journal_entries` in the query | Works in Chapter 1 |
| Sources | `campaign_panels.gd` panel `sources` and `data_card`; `science_data.gd` | Data Cards with measured, computed and limits sections |
| Plants | `plant_service.gd` `care_history`, `care_receipts`, stage events | Dated stages and care receipts per plant |
| Choices | — | Not stored (§5.4) |

### 6.2 Sections (tabs)

| Tab | Answers | Contents | Built from |
|---|---|---|---|
| **Now** | What am I doing, and what have we done? | Current objective in one sentence and why it matters; the last three completed tasks with dates; the **What now?** hint ladder (H1 → H2 → H3, 22 §2.3) | `scene_id`, catalog `exit_condition`, `completed_scene_ids`, `mission_receipts` |
| **Evidence** | What do we know, what do we think, what don't we know? | Three columns, **Observed / Inferred / Unknown** (22 T2). Clue cards carry source object, scene, date and evidence label; threads link clues to questions. Unknown holds the open-questions ledger (§4) as each question is raised | `acquired_evidence_ids`, `knowledge`, `knowledge_flags`, `journal_text.json` |
| **People** | Who are these people to us? | One page per person met: "What we know" (facts with their source) and "Moments" (relationship beats and optional moments); transcripts of every acknowledged line with its origin label (LOCAL LIVE, EARTH LINK, ARCHIVE 2034, TEXT) | `acknowledged_line_ids`, dialogue catalog origin labels, `story_log.moments` |
| **Garden** | How are Alo and Tara, and what grew from them? | The **Growth Record** (photo strip or conditions table, per D2) for each plant; the life-cycle track with each plant's marker; the lineage tree (Alo × Tara, Tara × Alo, generations); the ledgers (42 = 12 + 30; 15 + 15 in CH07; vault 12 → cotton 1 + 11 stored; working stock with no headline count); dedications | `plants[]` stages and care receipts, `inventories`, `story_log.choices` |
| **Decisions** | What did we choose, and what did it do? | Each confirmed choice: "What we chose", "What it did" (the option's canon `consequence` text), and "Where it showed up again" (added only when an echo fires). Outcome choices: the P-02 shift replay (M1-19) and earned upgrades | `story_log.choices`, `story_echoes.json`, receipts, `upgrades` |
| **Science** | What did we learn, and how do we know? | One concept card per completed scene from its canon `learning` block (concept → predict → observe → explain → transfer); earned Data Cards; the four evidence chips (§2.12) | catalog `scenes[].learning`, `evidence_tag`, `science_data.gd` |
| **Resume card** | Where was I? | Shown on Continue and in the pause menu (§6.6) | snapshot only |

### 6.3 Entry types and one shared shape

Types: **Objective**, **Work record**, **Clue**, **Question**, **Fact** (verified), **Interpretation** (inferred), **Person fact**, **Moment**, **Transcript**, **Growth photo**, **Ledger**, **Decision**, **Concept**, **Data Card**.

```json
{"id": "J-CH01-S03-LID", "tab": "evidence", "type": "clue", "status": "OBSERVED",
 "title": "Drawer lid", "body": "A pencilled plan for two seeds: one outside, one inside for comparison. The last line stops at \"Water at\".",
 "date": "2046-04-11 10:00 UTC", "scene_id": "EX-CH01-S03", "source": "drawer lid (camera)",
 "evidence_label": "Story", "links": ["J-Q-WHO-IS-N", "J-Q-WHY-TWO-SEEDS"], "gate_flag": "", "superseded_by": ""}
```

`status` uses SYS-07's states (UNKNOWN, OBSERVED, VERIFIED, LINKED, ARCHIVED) plus INFERRED for the Evidence board. `gate_flag` names the knowledge flag an entry needs before it can be shown or renamed. `superseded_by` lets a later record retire an earlier interpretation while keeping it visible (canon: "The original entry remains visible, with the new evidence added beside it", CH04-S01).

### 6.4 Update triggers (when the journal changes)

| Trigger | Existing hook | Journal effect |
|---|---|---|
| An evidence operation is committed | `grant_operation()` | Clue or Fact added; linked Question gains a thread |
| A knowledge flag unlocks (e.g. `noor_identity_revealed`) | `_grant_flag()` | Gated entries appear; N. entries are re-titled with an **Updated** badge; nothing is deleted |
| A scene's exit predicate passes | scene completion | Work record (Now) and Concept card (Science) |
| A decision review is confirmed | `record_choice` (new, §5.4) | Decision entry |
| An echo fires in a later scene | `story_echoes.json` lookup (new) | "Where it showed up again" line added to that Decision |
| A plant changes stage, or a photo is taken | `plant_stage_advanced` event; `apply_care("photo")` | Growth photo or stage entry; the life-cycle marker moves |
| A line is acknowledged | `acknowledge_line` | Transcript on the speaker's People page |
| A dated time card commits | `advance_time` | Date header in the dated list |
| A chapter debrief closes | ending flow (M1-19) | Chapter page: what we did, what we learned, open questions carried forward |

The journal is written **as things happen** and never rewritten to hide an earlier mistake; a corrected interpretation is marked superseded.

### 6.5 Spoiler rules

1. **Acquired only** (existing rule). Every entry is written from what the player saw or did; no entry quotes a scene's future prose (knowledge_service.gd header).
2. **Questions appear when a scene raises them,** never before. The Unknown column never lists a question the player has not yet had reason to ask.
3. **Names are gated by flag, not by keyword.** Noor's page is titled "N." until `noor_identity_revealed`; the 2034 engineer is "Engineer (2034)" until CH05-S05 completes. Gating uses each entry's `gate_flag`, which closes risk C8.
4. **No future consequences.** "Where it showed up again" is added only after it happens. A small thread icon on a Decision means "this is recorded", never "this will matter".
5. **Safety is never a spoiler.** Any safety fact the crew has is in the journal the moment it is known.
6. **Class mode:** a role-private card appears in the journal once delivered (canon, 10_GAMEPLAY_SYSTEMS §Role facts), so no clue is reachable only through a person.

### 6.6 The resume card ("Previously at Aurora")

At most six lines, built only from the saved snapshot, with no future content and no hidden values:

1. **Where and when:** location, scenario date and shift.
2. **Who is where:** shown only when the crew is split (CH04, CH08).
3. **Last thing you did:** the last completed scene's title and exit sentence.
4. **Now:** the current objective.
5. **The garden:** each living plant's stage in plain words.
6. **An open question:** the newest unresolved Unknown entry.

Examples:

> **Aurora · 25 April 2046 · dark shift 3.** You committed the daylight plan and practised the shelter drill. **Now:** read Mei's cold-and-thirst card with Rafi's warning, then plan shifts 3 and 4. **Garden:** Alo in bud, outside; Tara in bud, inside. **Open question:** Who is N.?

> **21 October 2046.** Rafi and Kai are on the ridge; Mei and Amara are at Aurora. You placed two beacons. **Now:** test the third link before the blind corner. **Garden:** twelve descendants, seven purple stems and five green. **Open question:** What is in the vault?

> **16 February 2047.** The storm steps are over. Earth does not answer; local radio works. **Now:** find which path failed. **Garden:** cotton has true leaves; the founder thirty are sealed, 15 + 15. **Open question:** How do we reach Earth again?

### 6.7 Sample Chapter 1 entries (`TEXT`, for `journal_text.json`)

| Tab · type | Entry |
|---|---|
| Evidence · Clue (Observed) | **Seed packet.** Two dry seeds, the word ALO and the initial N. The original stays sealed; we copied the label. |
| Evidence · Clue (Observed) | **Drawer lid.** A pencilled plan for two seeds: one outside, one inside for comparison. The last line stops at "Water at". |
| Evidence · Interpretation (Inferred) | Whoever left the seeds planned the same two-chamber test we are running. |
| Evidence · Question (Unknown) | Who is N.? · Why only two seeds? |
| Garden · Growth photo | **Alo, 12 April.** Two seed leaves open. Moisture inside the calibrated band. |
| People · Moment | **Kai** checked the corridor switch twice. Rafi hung a hand light beside the locker, handle out. |
| Decisions · Decision | **Spare sunlight → planting bay.** The empty garden glowed until 25 April. |
| Science · Concept | **A full store can't take more.** Check where energy can be used or stored before calling it spare. |
| Evidence · Clue (Observed), CH01-S12 | **A recording, not a call.** It played when we tagged the bloom photo. Nobody could call us: the Earth link was down. |

---

## 7. Revised scene treatments and sample dialogue

Lines are quoted by id, word for word. New spoken lines are marked **[CANON CHANGE — needs approval + re-recording]** and each has a no-voice alternative. Beats are numbered so cutscene and code tasks can cite them (for example "§7.5 beat 4").

### 7.1 The opening (cold open → `EX-CH01-S01`..`S03`)

**Goal:** a clear visual identity (mustard gold against regolith grey and black sky), stakes in the first minute, the player's first meaningful action within about 60 seconds of control, and the crew introduced by what they do.

**Current state:** CS-01 (v7, `production/cutscenes/v7/src/CS-01.json`) is three shots with a title card and all four S01 lines between 14 s and 32 s, so the player watches about 40 s before touching anything.

| Beat | Picture | Sound | Player | Label |
|---|---|---|---|---|
| 1 *(optional, P1)* | Earth. A mustard field in winter morning light, yellow to the horizon, moving in the wind. No person, no caption. 6 s | `SFX_EARTH_FIELD_MORNING` (wind, birds) | — | `ASSET` (one new shot, M1-52). Fiction; it makes no claim about Alo |
| 2 | Hard cut to the Moon: Aurora's mast on the crater rim, low Sun, long black shadows, black sky (CS-01-A exterior, with the M1-45 fixes) | **Total silence** for 2 s. Caption: [no sound outside] | — | `STAGING`. The cut from wind to nothing teaches the vacuum rule without a word |
| 3 | Push through a viewport into the commons; on-screen text: "Aurora Station · lunar south pole · 11 April 2046 · 06:00 UTC", with a small "Story (2046)" chip | `SFX_FAN_NORMAL` fades in: the station is alive | — | `STAGING`, `TEXT` |
| 4 | Close on the battery display: a gold band reaches the top. Title LAST LIGHT ACADEMY over it for 2 s. If beat 1 exists, the yellow of the field and the gold of the band are matched | Fans | — | `STAGING` |
| 5 | Control. Third-person follow behind Mei to the mission table. On the way each cadet is caught in an action, with a role tag that fades: Kai's hand on a switch, stopping (orange); Amara's finger on the overflow arrow (cyan); Rafi turning the emergency card towards each seat (purple); Ferreira on the Earth console (gold tab), watching. The camera rests one second on four mugs with no names | Fans | Walk (move and look taught here) | `STAGING` (crew blocking per M1-17) |
| 6 | At the table: Kai: "A full battery sounds like a good problem." (`EX-CH01-S01-L01`) Amara: "Only if we notice what spills." (`L02`) | Lines in-engine, captioned LOCAL LIVE | The player traces production → storage → overflow and **predicts** where extra energy goes | `CODE` (lines move from CS-01 into play) |
| 7 | Mei: "Can we store it somewhere that is not a battery?" (`L03`). The preview shows the air gauge rising or the garden glowing | | **First meaningful action:** choose Store air or Light the planting bay (D1) | canon choice |
| 8 | Ferreira (Earth link): "Show each other your reasoning, then commit it." (`L04`), heard just before commit | `SFX_RADIO_EARTH_IN` latency texture | Commit; the result stays visible | canon |
| 9 | Rafi turns the emergency card to every seat; the charter is acknowledged | `CUE-01` enters here, after the charter (canon cue rule): music arrives as the crew accepts the station | Acknowledge charter | canon |
| 10 | S02: the Safe Room roll call. In the background the inventory lamp on the dry-storage drawer blinks once | `SFX_INVENTORY_LAMP_TICK`, quiet | Rehearse | `STAGING`, `AUDIO` (bridge to S03) |
| 11 | S03: the blinking lamp; the drawer; the packet: ALO and N. The inspection camera finds the pencilled plan inside the lid (§4 clue 2) | `CUE-01` sparse stems | Inspect, copy the label, calibrate the probe | canon + `TEXT` |

**Lines:** all eleven beats use only existing lines (`EX-CH01-S01-L01`..`L04`, then S02 and S03 as written). **No canon change.** CS-01 is re-edited from its own shots to beats 2–4 (about 12–15 s), and the S01 lines play in-engine (M1-51 with M1-10).

### 7.2 An Alo-and-Tara care interaction: the Care Round (`EX-CH01-S04`, `S05`; reused in CH02-S05, CH03-S08/S12, CH05-S12, CH06-S12, CH07-S10, CH08-S05)

**Goal:** attachment through repeated, varied, physical care for **both** plants, with growth the player sees in their own photographs.

**The loop (2–3 minutes, one per care day):**

1. **Observe.** Walk to the plant. Read its posture: leaning towards the lamp (seedlings bend towards light), leaves drooping when thirsty, cupped in cold, upright after care. No face, ever.
2. **Measure.** Moisture with the calibrated probe (the 40–60 band from P-01) and the chamber temperature. Alo is reached through the glove ports of the exterior test chamber (`SFX_GLOVE_PORT`); Tara directly in the indoor reference bay. The two readings appear side by side, because Tara is the reference that makes Alo's readings mean something ("A reference is a plant we care for, not one we ignore." `EX-CH01-S04-L02`).
3. **Photograph.** The camera opens with a faint ghost of the previous photo overlaid. The player lines up the frame and takes it (`SFX_CAMERA_SHUTTER`). Lining up is generous (a wide tolerance, no pixel precision; Family Mode snaps). The photo files itself to the Growth Record (`apply_care("photo")`).
4. **Act.** One small, specific care problem, different each day: top up to the band; check a service connection on Tara's bay; compare a root photograph (canon S05 list); move the work light so Kai can hold it still; note a new leaf.
5. **Record.** Mei's pencil writes the dated entry; the life-cycle marker moves.

**Crew in the room (`STAGING`, M1-17 companions):** Kai holds the work light steady ("One lamp held still. I can manage that." `EX-CH01-S04-L03`); Amara reads labels back; Rafi checks the transfer lid; on the day the first bud appears all four lean in for the photo, and the bud photo is the first one with people's shoulders in it.

**Dated content for CH01** (from §3.8): 12 Apr cotyledons on both plants · 15 Apr Alo's first true leaves · 16 Apr Tara's first true leaves, a day behind, which the conditions table explains · 18 Apr bud clusters on both plants (the code's `bud` stage starts on day 7 for each); Amara's "Fourteen dated care entries. A bud is a useful result." (`EX-CH01-S05-L04`) arrives on the last visit · Tara's buds stay tighter for longer, which is why she opens three days after Alo (30 Apr against 27 Apr, `bloom_days` 19 against 16).

**Lines:** existing S04 and S05 lines only. **No canon change.**

### 7.3 Alo's natural death and farewell (`EX-CH03-S09` → vigil → `S10` → `S11`)

**Goal:** the emotional peak of the first half. Restrained dialogue, silence, familiar objects, crew reactions, and a farewell the player performs. Senescence is shown as the completion of a life the player helped to finish, never a failure of care.

| Beat | What happens | Sound | Label |
|---|---|---|---|
| 1 (S09, 16 May) | The Growth Record opens Alo's first photo (12 Apr, two seed leaves) beside today's: pods swollen, lower leaves yellowing, stem leaning. Mei: "The photograph was a flower. This is still Alo." (`EX-CH03-S09-L01`) | `CUE-05` minimal bed | canon + `STAGING` |
| 2 | Kai: "Can we make the lamp help?" (`L02`). The paused preview adds light: nothing that matters changes. Amara: "This is maturity, not the old cold alarm." (`L03`). The journal shows the life-cycle track she has been on since 11 April, its last stage labelled "seeds" | | canon (22 §5.3) |
| 3 | Rafi: "We can stay while you do the checks." (`L04`). The player approves the five-day dry-down; the date card names the five days | | canon |
| 4 (vigil, 17–21 May) | Five short visits. One photo a day in the same frame (the ghost overlay makes the change visible): leaves curling and browning, pods drying. On the third day a petal falls against the chamber wall: the petal of S10. On the fourth, Kai leaves Mei's named mug of tea on the bench and goes without speaking | No music. `SFX_GREENHOUSE_FAN` only | `STAGING`, moments `CH03-ALO-VIGIL-1`..`5` |
| 5 (S10, 21 May; CS-06) | The final drying check. The player opens the pods over the contained tray; seeds fall | `CUE-05` stops; only `SFX_SEED_TICK` | canon |
| 6 | Mei: "I thought keeping her alive meant longer." (`EX-CH03-S10-L01`) Amara: "It meant she could finish." (`L02`). Amara's hand on Mei's shoulder | | canon (CS-06-B) |
| 7 | Kai half rises: "Do you want us to wait?" (`L03`). Mei: "Stay. Then help me count." (`L04`). Kai sits back down | | canon |
| 8 | Counting together: the player places seeds into wells in four groups, one per cadet; the tally climbs; no timer | Seed ticks | canon (P-06) |
| 9 | The tally reaches 42. Three seconds of only fans. **[CANON CHANGE — needs approval + re-recording]** Amara, quietly: **"Forty-two."** · *Alternative without a new line:* the tally card turns to 42 with a soft `SFX_UI_SHIFT_COMMIT`, all four look at it, and Rafi's existing "Thirty founder seeds remain sealed." (`EX-CH03-S11-L02`) is the first thing said in S11 | Fans | canon ("The final total is read aloud") |
| 10 | Allocation 12 + 30 is sealed. The player sleeves the petal, then lifts Alo's nameplate from its holder and sets it on the lineage board above the petal | `CUE-05` returns at half level | canon + `STAGING` |
| 11 (S11) | The cleaned cassette becomes position 1 of the twelve. The camera repeats the exact CH01-S04 planting angle. Amara: "Parent line first: Alo times Tara." (`EX-CH03-S11-L01`) | `CUE-02` | canon ("the same close framing as Alo's original planting") |

**Journal entry written at beat 10 (`TEXT`):** "Alo · 11 April – 21 May 2046. Completed her life cycle: flower, pods, forty-two seeds. Parent of every plant in this garden." **Debrief line (`TEXT`):** "Alo did not die because of anything you did. Mustard is an annual plant: after its seeds ripen, the parent plant dries and dies. Your care let her finish." (Source: [Fast Plants life cycle](https://www.fastplants.org/pdf/activities/FP_life_cycle.pdf), stages I–J.)

### 7.4 Ferreira's confession and what follows (`EX-CH05-S02` → `S06`, then CH06–CH08)

**Goal:** the confession lands because the player has seen eleven small signs (§3.5 F1–F11) and because it is staged as an equal conversation, not a performance. Its timing is unchanged.

| Beat | What happens | Label |
|---|---|---|
| 1 (S02, 12 Dec) | First watch. Ferreira stops for a second at the N.R. hatch cover, touches it and moves on; Amara sees it. She unpacks a sealed document sleeve from her relief cargo and leaves it unopened on her locker shelf | `STAGING` (bridge to S03) |
| 2 (S03, 14 Dec) | She brings the sleeve to the table and sets four records under transparent weights without arranging them (canon). "First the records. Then my memories." (`EX-CH05-S03-L01`). The player reconstructs the order (P-09) | canon |
| 3 (S04) | Mei revises the "old garden" caption while Ferreira watches and does not ask her to soften it (canon) | canon |
| 4 (S05, CS-09) | Static shared frame, no music, fans only. Ferreira sits where a commander would usually stand; her hands rest on the table, away from the records. **Three seconds of silence** before she speaks | `STAGING` (CS-09 is in-engine) |
| 5 | Ferreira: "I was the engineer who could not fix the radio." (`EX-CH05-S05-L01`) | canon |
| 6 | The player chooses Mei's first question (D9). Each choice highlights the line on the matching record as the facts are acknowledged (the retreat order, or what came home), so the account in the prose (C3) arrives through records, not a speech | canon choice + `STAGING` |
| 7 | Mei: "You could have told us." (`L02`) Ferreira: "Yes. I was afraid of how it would sound." (`L03`) | canon |
| 8 | Ferreira turns the evacuation order over. On the back, in her hand: "Radio not restored. Retreat ordered. Garden left on minimum heat. I told her someone would come back for it. — Ferreira" (clue 18) | `TEXT` `[STORY CHANGE — needs Sadman's approval]` |
| 9 | Kai: "Then we can ask before we guess." (`L04`). The disagreement stays visible: Mei does not forgive on cue (canon "This is not a forgiveness meter") | canon |
| 10 | She leaves one record at her place (D9: ascent manifest or greenhouse service note); it stays there through CH06–CH07 | `STAGING` |
| 11 (S06) | She leaves the personal identity page with Rao for consented release and takes her mug back to the watch station (canon) | canon |

**After:** the change is behavioural and gradual (§3.5 table): she waits in doorways (CH06), gives up the head of the table (CH07-S01), teaches the housing (CH07-S10), asks rather than does at the summit (CH08-S07), gives the credit away (CH08-S10), and has to be pulled into the photo (CH08-S12). **No canon line changes.**

### 7.5 Noor's first live call (`EX-CH08-S08` → `S09` → `S10`; CS-15)

**Goal:** anticipation, framing, pauses and reactions across three places (summit, Aurora, Earth), with the communication checks still playable before the voice. The player knows Noor through her packet, her recordings, her notes and her texts; this is her arrival as a person, not a reveal.

| Beat | Picture | Sound | Player | Label |
|---|---|---|---|---|
| 1 (S08) | Two signal panels; only one points to Earth | Cabin hum; checkbacks; no music | Tune the local leg first, then the Earth dish with its obstruction indicator; both lock independently | canon (P-16) |
| 2 (S09) | ALO42 returns exactly | | Compare the near-match and the exact reply | canon |
| 3 | When the Earth leg locks, two backlogs cross on the data panel: Aurora's "Queued for Earth" outbox from the blackout finally sends, and Rao's listening log scrolls in, one line every few hours for 52 days: "Aurora, Earth. Listening." | Soft data ticks | Read, or skip | `TEXT` (clue 22) |
| 4 (S10) | The transmit control waits until both path checks are visible (canon) | | Confirm Aurora's voice check, then Earth's; captions read [local voice check passed] and [Earth voice check passed] | canon + `TEXT` |
| 5 | Rao's channel opens | `SFX_RADIO_EARTH_IN`, the latency texture the player has not heard since 14 February | — | `AUDIO` |
| 6 | Rao identifies the route (prose, C2). **[CANON CHANGE — needs approval + re-recording]** Rao: **"Aurora, Earth. We hear you. Go ahead."** · *Alternative without a new line:* Rao's console text "EARTH: ROUTE CONFIRMED · CHANNEL OPEN", and the listening log's last line updates to "Aurora, Earth. We hear you." | | — | |
| 7 | Cut to the rooftop in Dhaka, morning (08:15 local; §2.12): the camera arcs from behind Noor to her face (CS-15-B, accepted). Her finger rests over the transmit control. She chooses | `SFX_DHAKA_ROOFTOP_MORNING`; then 2.6 s of nothing but the open channel | — | `STAGING`; the Moon is not shown in her sky |
| 8 | Noor (first live Earth voice): "Hello, Aurora. This is Noor." (`EX-CH08-S10-L01`). Her caption carries a label the player has never seen beside her name: **EARTH LINK · LIVE** (before: ARCHIVE 2034, then TEXT) | `CUE-11` enters only after her line ends (canon: "give Noor first words room") | — | canon + `TEXT` |
| 9 | Reactions, intercut: at Aurora, Mei's hand goes to the "N." holder (D10 `OPT02`) or the photo strip (`OPT01`); Amara looks at Mei. In the summit cabin Kai looks at Ferreira; Ferreira closes her eyes for one beat (the radio she could not fix is carrying this). Rafi checks the clock | Summit cabin hum, Aurora's low-power fans and the rooftop morning, each under its own picture | — | `STAGING` |
| 10 | Mei: "We kept a place for you." (`L02`). The 2.6-second round trip passes in silence | | — | canon |
| 11 | Noor's reply (prose, C2: "she says the crew did what she could not"). **[CANON CHANGE — needs approval + re-recording]** Noor: **"You finished what we could not."** · *Alternative without a new line:* on her tablet Noor opens the Alo × Tara lineage photo and touches it; on Aurora's screen the receipt reads "Opened by N. · 02:31 UTC". She answers with an action, as she always has | | — | |
| 12 | Ferreira: "You brought us the seeds." (`L03`). Amara: "The garden has more than one gardener." (`L04`) | | Choose the supported report sentence (canon) | canon |
| 13 | On-screen: "Return departs 03:00" as Rafi reads the clock (canon prose) | `CUE-11` sustain | — | `TEXT` |

**Shot and audio notes for the CS-15 lane (time-sensitive, C7):** CS-15 is planned as A 5 s, B 9 s, C 5 s, D 8 s. Keep B (the arc to Noor) as the moment before her first word; put the 2.6 s pause on the cut into B, not after it; mix the three ambiences per picture and never under one another; no music under her first words.

### 7.6 Tara's resolution and the final garden (`EX-CH03-S12` beat, `CH05-S12`, `CH08-S12`; CS-17)

**Tara's farewell, 31 May 2046** (first beat of CH03-S12; `[STORY CHANGE — needs Sadman's approval]`, §3.9):

1. Tara's dry pods, five days after her watering stopped on 26 May. All four cadets in the indoor reference bay. `CUE-02` at low level.
2. The player takes Tara's last photo in her own frame; the ghost overlay shows her 12 April seed leaves.
3. Mei opens the pods into a labelled envelope: **"Working stock — Tara × Alo"**, with no headline count. Amara seals it. Rafi checks the founder ledger on screen: still 30.
4. Kai carries Tara's nameplate to the lineage board and sets it level with Alo's petal.
5. Mei writes on Tara's card (`TEXT`, no voice): "Thank you, Tara. Your seeds are the ones we use, so Alo's thirty can stay sealed."
6. Mei leaves Tara's name on the empty bay's frame. No new spoken line.

**Cotton in Tara's bay, 15 Dec 2046 (CH05-S12, canon "indoor reference bay"):** the player plants cotton under Tara's name; Mei places the petal beside the label (canon). The manifest note (clue 14) is pinned on the bay: "Let one grow further."

**The final garden, 10 April 2047, 06:00 (CH08-S12; CS-17):**

| Beat | What happens | Echo of | Label |
|---|---|---|---|
| 1 | Final checks: five home, thirty founder seeds, eleven vault specimens, pressure and temperature steady, cotton alive (canon). Mei: "Temperature and pressure steady." (`EX-CH08-S12-L01`) Amara: "Seeds protected. Everyone home." (`L02`) | CH01-S12 ("Chamber safe. Now we open it.") | canon |
| 2 | Mei opens the shutter: low white sunlight, black sky, long shadows | `SFX_SHUTTER_OPEN`, the same sound as CH01-S12 | canon + `AUDIO` |
| 3 | Descendants in flower, purple stems and green stems together: both parents visible in the garden | CH02-S06 prediction, CH04-S01 count | `STAGING` |
| 4 | The lineage board: Alo's petal, Tara's nameplate, "Alo × Tara" and "Tara × Alo", the tray dedication (D6), Ferreira's 2034 record (D9), Rafi's paper bee, and the Growth Record strip in the player's layout (D2) starting with 12 April | CH01-S04, CH02-S02, CH03-S10, CH05-S05 | `STAGING`, `ASSET` |
| 5 | Noor (live Earth link): "Show me the cotton by the window." (`L04`). Mei turns the camera to the cotton in Tara's bay; the frame slides down to Tara's name on the bay frame and the pinned manifest note | Clue 14; §3.9 | canon + `STAGING` |
| 6 | Ferreira: "You did not just survive the Moon. You grew it." (`L03`) | CH02-S01 "You did not just endure the night. You operated it." | canon |
| 7 | The shared photo: five named mugs on the table; Kai's hand light on his belt (D11); the Day-one photo pinned beside the strip (D1); Ferreira at the edge until Mei pulls her in; Noor on the screen inside the frame. The player presses the shutter | CH01 mugs, CH04-S12 fifth mug | `STAGING` |
| 8 | The photo becomes the last Growth Record entry. The player chooses the dedication (D13); `CUE-12`; credits name both teams and the people who made their first chance possible (canon) | — | canon |

**CS-17 note (time-sensitive, C7):** CS-17-C/D are still planned ("petal sleeve beside blank lineage label + Ferreira line; shared photo by the cotton with Noor on a tablet"). Add Tara's nameplate beside the petal and a named label instead of a blank one, and five named mugs in D. These are frame edits on start frames, not new shots.

### 7.7 The Mars teaser (CS-18, post-credits)

**Goal:** one restrained detail that asks a question, while the story stays complete. No quest, collectible or task (canon).

| Beat | Picture | Sound |
|---|---|---|
| 1 | The dry-storage cabinet from CH01-S03. The ALO drawer stands open and empty; its packet is in the archive. Beside it, a closed drawer labelled MARS in Latin letters. Leaning on the cabinet top: the shared photo the player just took | `SFX_FAN_NORMAL` |
| 2 | Hold for three seconds. The inventory lamp beside the MARS drawer blinks once: the same blink that opened the mystery ("The inventory lamp blinks beside a drawer that seems too small to contain a story.", CH01-S03 prose) | `SFX_INVENTORY_LAMP_TICK`, once |
| 3 | Black. If the player chose "For the gardens we leave for others" (D13), those words sit small at the bottom of the black for two seconds | Silence |

The question it leaves: the station has just registered something in a drawer nobody has opened. Who put it there, and for whom? **Optional second detail (choose one, never both):** the MARS label holder carries a blank identity label, like the two Amara wrote before anyone could name a seed ("Two labels first. Names second." `EX-CH01-S03-L03`).

**Production:** reuse the accepted CS-18-A still (notes_C.md); add a four-frame lamp-blink overlay and the effect in `compose_cutscene.py`; 6 s becomes 8 s. No new generation, no Mars science claim, no logo. **No canon change.**

---

## 8. Prioritized change list

**P0** must land before the 13 Nov submission; the demo is Chapter 1, so every P0 item is Chapter 1 work that uses existing footage, lines and assets. **P1** is the full campaign. "Canon?" says whether the item alters locked canon; every item that does is gated on Sadman's approval and has a compatible alternative.

| # | Pri | Change | Label | Affected files | Depends on | Scope | Observable acceptance | Canon? | Board |
|---|---|---|---|---|---|---|---|---|---|
| NR-01 | P0 | Save schema 3 with `story_log` (choices, moments); `record_choice` and `record_moment` verbs; Chapter 1 choices recorded on confirm | `CODE` | `game/scripts/core/campaign_state.gd`, `campaign_director.gd`, `game/scripts/save/save_service.gd`, `game/tools/test_*.gd` | — | S–M | A v2 save loads and migrates; confirming `EX-CH01-S01-CHOICE` adds one `story_log.choices` entry; a preview adds none; a repeated `command_id` adds nothing; `game/tools/run_tests.sh` passes | No | `M1-47` |
| NR-02 | P0 | Journal v1 for the demo: Now, Evidence (Observed / Inferred / Unknown), Garden, Decisions tabs and the resume card, inside the existing `journal_discovery` panel | `CODE` (UI) | `game/scripts/ui/campaign_panels.gd`, `chapter1_campaign_hud.gd`, `game/scripts/dialogue/knowledge_service.gd` | NR-01, NR-04 | M | Screenshots of every tab after CH01-S03 and after S12; "Noor" never appears; the resume card shows at most six lines on Continue; text reflows at 150% | No | `M1-48` |
| NR-03 | P0 | Chapter 1 Care Round with dated photos for Alo **and** Tara (ghost overlay, `apply_care("photo")`); S01 lines in-engine (§7.1 beats 5–8); bridges: inventory-lamp blink in S02, mugs named in S12, Tara's own close view | `CODE`, `STAGING` | `game/scripts/campaign/`, `game/scripts/world/`, `game/scripts/biology/plant_service.gd` (read only), `game/tools/` | NR-01 | M | Two photos on two dates appear in the Garden tab for each plant; a second photo the same day is refused; S02 shows the blink; S12 ends with four named mugs; run_tests passes; screenshots in `production/qa/evidence/` | No | `M1-49` |
| NR-04 | P0 | Chapter 1 text pack: journal entries, questions, resume templates, the drawer-lid note (§4 clue 2), mistake feedback (§2.10), Alo Lost debrief text, `story_echoes.json` rows for D1 and D2 | `TEXT`, data | new `game/resources/campaign/content/journal_text.json`, `story_echoes.json` | — | S | Valid JSON; English only; no Bangla script; no future names; every entry two sentences or fewer; Sadman sees the list of new text in the evidence | No (new world text) | `M1-50` |
| NR-05 | P0 | Re-edit CS-01 into the cold open (§7.1 beats 2–4): 2 s of exterior silence, interior hum, title over the gold band; the S01 lines leave the film for in-engine play | `STAGING` (cutscene) | `production/cutscenes/v7/src/CS-01.json` (or a v8 copy), `game/assets/cutscenes/CS-01_Arrival.ogv` | — (coordinate with M1-10, M1-45) | S | The cut runs 12–15 s; no airborne sound on the exterior; control reaches the player within 20 s of the cut ending; captions present | No | `M1-51` |
| NR-06 | P1 | Opening beat 1: a 6 s Earth mustard-field shot and `SFX_EARTH_FIELD_MORNING` | `ASSET`, `AUDIO` | `production/cutscenes/`, `production/audio/sfx_list.csv`, `production/AI_PROMPT_LOG.md` | NR-05; Sadman approves the start frame | S | Shot reviewed (four-petal flowers, no person, no text); logged; matched cut to the gold band | No | `M1-52` |
| NR-07 | P1 | **Canon proposal pack:** Tara's dated resolution and working stock (§3.9); Ferreira's margin note (clue 18); the three optional lines (§7.3 beat 9, §7.5 beats 6 and 11); the cotton manifest note (clue 14); Rao's listening log (clue 22); the dedication texts (D6). After approval, apply to canon, re-record and update the docs (character bible Tara entry and its "stylised eyes" line, handbook §4 Tara row) | `[STORY CHANGE]`, `[CANON CHANGE]` | `full-game-story/STORY_FULL.md`, `story-data.json`, `production/audio/vo_lines.csv`, `PRODUCTION_HANDBOOK.md`, `game-design/04_CHARACTER_BIBLE.md` | Sadman's approval | M | Sadman's decision recorded per item in the handbook §3; approved lines recorded with ElevenLabs and logged; catalog rebuilt; declined items fall back to the alternatives in §7 | **Yes — needs Sadman's approval first** | `M3-94` |
| NR-08 | P1 | Tara lifecycle in code: `mature_days` 45, harvest to a working-stock ledger with no headline count, `archived_nameplate` state; Alo vigil photos allowed through 21 May | `CODE` | `game/scripts/biology/plant_service.gd`, `game/resources/campaign/profiles/campaign_rules.json`, tests | NR-07 (Tara item approved) | S | Tara reaches `mature_pods` 26 May and harvests 31 May; founder 42 = 12 + 30 unchanged; a test fails if the working stock enters the founder ledger | **Yes (story fact) — needs Sadman's approval first**; alternative keeps the 22 May end | `M3-96` |
| NR-09 | P1 | Cutscene staging: CS-15 (§7.5 beats 5–11), CS-17 (Tara's nameplate, named label, five named mugs), CS-18 (lamp blink and effect) | `STAGING` (cutscene) | `production/cutscenes/v8/`, `game/assets/cutscenes/` | NR-07 for the two line beats; the rest can start now | M | CS-15 has the 2.6 s pause and no music under Noor's first words; CS-17-D shows five named mugs and Tara's nameplate; CS-18 blinks once; every shot passes the ART_BIBLE §2 checks | Partly (only the line beats) | `M3-97` |
| NR-10 | P1 | Story echoes and environmental clues for CH02–CH08 (D4–D13; §4 clues 10–22 objects; montage beats §2.9; Rafi's posture hook; the beacon layer) | `CODE`, `STAGING` | `game/scripts/campaign/`, `game/scripts/world/`, `game/resources/campaign/content/story_echoes.json` | NR-01, NR-04; NR-07 for story-change items | L | For each D-row, a test sets the option and asserts the echo object or journal line appears in its later scene and not before | Partly | `M3-95` |
| NR-11 | P1 | Full journal: People and Science tabs, flag-gated names (fixes C8), superseded entries, chapter pages, Class-mode cards | `CODE` (UI) | `game/scripts/ui/`, `game/scenes/ui/`, `knowledge_service.gd` | NR-02; coordinate with M3-90 | M | A run through CH05-S10 shows "N." before and "Noor" after with an Updated badge; no entry appears before its scene | No | `M3-98` |
| NR-12 | P1 | Assets and audio: Alo cotyledon, true-leaf, senescent and dry variants; Tara pods, senescent and dry; Alo and Tara nameplates; five named mug decals; the gear-wheel tool tag; drawer-lid note; "N." label holder; working-stock envelope; `SFX_INVENTORY_LAMP_TICK`, `SFX_DHAKA_ROOFTOP_MORNING` | `ASSET`, `AUDIO` | `production/concept/`, `game/assets/`, `production/ASSET_REGISTRY.csv`, `production/audio/sfx_list.csv` | 2D sheets approved by Sadman before any Tripo credit | M | Every plant variant has four-petal flowers where flowers show and no face; registry and AI log updated; captions in `sfx_list.csv` | No | `M3-99` |

**What alters locked canon** (all in NR-07, each with its alternative in §7): Tara's dated end and working stock (alternative: keep the coded 22 May end, stage only the nameplate and the bay); Ferreira's margin note (alternative: omit it; the records carry the facts); Amara's "Forty-two." (alternative: the tally card and Rafi's existing S11 line); Rao's "Aurora, Earth. We hear you. Go ahead." (alternative: console text and the log's last line); Noor's "You finished what we could not." (alternative: she opens the lineage photo and the receipt shows it). The cotton manifest note, the drawer-lid note, Rao's listening log and the dedication texts are new written text with no conflict with canon; they are in the pack so Sadman sees them, and they can ship as `TEXT` if he prefers.

---

## 9. Coverage map

### 9.1 The ten areas of the brief

| Area and bullet | Answered in |
|---|---|
| **1 Noor's mystery:** deliberate clue sequence; for each clue where found, what it establishes, inference, what stays open, payoff | §4 table (23 rows) |
| 1 Environmental evidence, recordings, incomplete records, character reactions | §4 clues 2, 10, 12, 14, 18, 22; §2.3 |
| 1 Never mislead through information characters would share, especially safety | §4 reveal rules; §3.5 rule; F4 |
| 1 Keep the CH05 identity reveal; first live voice in CH08-S10 as an arrival | §4; §7.5 |
| **2 Character stories:** motivation, fear, behaviour, vulnerable moment, contribution, later change; proportional; through action | §3.1–§3.7 |
| 2 Ferreira: subtle signs before, gradual change after, timings kept, never withholds safety | §3.5 (F1–F11, after-table); §7.4 |
| **3 Alo and Tara:** attachment through varied care, photos, records, care problems, crew reactions | §7.2; §3.8 |
| 3 Alo's growth step by step, scientifically correct, dated | §3.8 table; §2.12 sources |
| 3 Tara comparable care and significance | §3.9; §7.2; §7.6 |
| 3 Alo's end-of-life scene: interaction, restraint, silence, objects, reactions, player takes part, not a failure | §7.3 |
| 3 Preserve natural death after seeds, descendants, 42 = 12 + 30, no plant faces or speech | §3.8, §3.9, §7.3, §7.6 |
| 3 Tara's outcome: canon checked; labelled proposal visible in the final garden and lineage | §1.3 C1; §3.9; §7.6 |
| **4 Choices:** options and evidence, immediate consequence, persistent state, later scene, recognition, reconnection | §5.2 (D1–D13) |
| 4 Fits the campaign structure and save system; outcome versus interpretation, preparation, relationship; safety first; contracts kept | §5.1, §5.4 |
| **5 Gameplay and learning:** distinct emphasis per chapter tied to its emotional purpose | §2.1–§2.8 rows "Distinct gameplay challenge" |
| 5 Short learning challenges inside practical tasks (predict, measure, compare, verify) | §2.10 first table; each chapter's "Learning objective" |
| 5 Recoverable mistakes with specific feedback and real retry; constructive failure debriefs | §2.10 second table and debrief template |
| **6 Mission journal:** objectives, clues and sources, facts versus interpretations, people, Alo and Tara, decisions, science | §6.2, §6.3 |
| 6 Only discovered content; update triggers; resume without spoilers; mapped to code | §6.1, §6.4, §6.5, §6.6 |
| **7 Cinematic presentation:** strong opening | §7.1 |
| 7 Mystery in the annex and abandoned spaces | §2.3; §4 clues 10–12 |
| 7 Music, sound and silence with cue and effect ids; lunar sound rules | §2.11; every chapter row |
| 7 Noor's first live call with the checks playable before | §7.5 |
| 7 Captions, transcripts, visual cues | §6.2 People tab; §7.5 beat 8; §2.10 |
| **8 Pacing, dialogue, transitions:** natural, distinct voices; no fact speeches | §3 (voice per character), §7 (records carry facts, C3) |
| 8 Balance of suspense, action, discovery, emotion, recovery | §0 rule N4; §2 chapter rows |
| 8 Smooth chapter transitions; a varied hook at every chapter end | §2.9; each chapter's last row |
| **9 Science transparency:** four classes; verified new claims with links; Moon, plants, radiation, storms, eclipse, communications | §2.12 |
| 9 Keep the 2017 replay and the 2012 counterfactual; no fiction as NASA data | §2.12 |
| **10 Ending and Mars teaser:** first planting to final garden through objects, places, gestures and the player's records; reflect choices; resolve arcs | §7.6; §5.3 |
| 10 Restrained, intriguing post-credits detail; story still complete | §7.7 |
| Deliverables: audit; chapter table; bridge list; arcs; Noor timeline; decision map; journal spec; treatments; change list | §1; §2.1–§2.9; §3; §4; §5; §6; §7; §8 |
| Board tasks and `board.py check` | §8 board column; `production/plan/tasks.json` |

### 9.2 Sadman's Banglish notes

| Point | Answered in |
|---|---|
| Make Noor more intriguing | §4 (new clues 2, 12, 14, 18, 22), §3.7 |
| Every character an emotional story | §3 |
| Deeper attachment to Alo and Tara | §7.2, §3.8, §3.9 |
| Alo's death more emotional | §7.3 |
| Show Ferreira's past and regret better | §3.5, §7.4 |
| Noor's voice reveal more cinematic | §7.5 |
| Decisions change the story and carry into later chapters | §5 |
| Different gameplay per chapter | §2.1–§2.8, §2.10 |
| A mission journal | §6 |
| Wrong decisions teach instead of only game over | §2.10 |
| A more cinematic, attractive opening | §7.1 |
| More mystery in the old greenhouse and abandoned places | §2.3, §4 clues 10–12 |
| Music and effects for suspense | §2.11 |
| Alo's growth shown step by step | §3.8, §7.2 |
| NASA real data and fiction clearly separated | §2.12 |
| Accurate Moon, solar-storm and eclipse science | §2.12, §2.11, §1.3 C4 |
| Small interactive learning challenges | §2.10 |
| An emotional journey from the first Alo to the final garden | §0, §7.3, §7.6 |
| A more mysterious Mars teaser | §7.7 |
| Tara's outcome clear | §3.9, §7.6 |
| Smoother chapter transitions | §2.9 |
| Natural, non-robotic dialogue | §3, §7 (existing lines carried by staging; 3 optional new lines) |
| Balance of suspense, emotion and action | §0 N4, §2 rows |
| An interesting hook at every chapter end | §2.1–§2.8 last rows |

### 9.3 The 4 November message

| Point | Answered in |
|---|---|
| Scenes with no gap, one totally connected to the next | §2.9 (all 102 joins, 6 fixes, montage beat sheets) |
| People should feel attached | §7.2, §7.3, §3 |
| Like premium narrative games (principles only) | §0 rules and N1–N6 |
| Super smooth scenes | §2.9, §7.1 (control within 20 s of the cut) |
| Easily playable and fun for all people | §2.10 "Easy to pick up" and "Why it is fun"; Family / Cadet / Engineer |
| Students have fun doing puzzles and learn too | §2.10 learning-challenge table; 22 (per-mission puzzles) |
