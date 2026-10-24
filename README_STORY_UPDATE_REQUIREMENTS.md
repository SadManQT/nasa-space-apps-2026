# LAST LIGHT ACADEMY — Story Update Requirements

**Team:** The Last BrainCell  
**Challenge:** NASA Space Apps Challenge 2026 — Build a Junior Astronaut Mission Trainer  
**Document type:** Proposed change requests; **not** a replacement for the approved story canon  
**Status:** Planning / review — checkboxes must not be read as completed work

## 1. Goal

Strengthen the existing story's clarity, emotional stakes, scientific transparency, and judge-facing accessibility **without rewriting its identity**. The core premise remains: four cadets maintain Aurora Station near Shackleton crater, protect the crew, and help Alo (আলো), a mustard flower, survive until first light. The story expands into *The First Moon Garden* and the Noor/Expedition Zero mystery.

**Hackathon narrative target:** a self-contained Chapter 1 (*Night One*) with an effective closing hook (the message from N. and the need for Tara). Chapters 2–8 remain a coherent roadmap, not a requirement for the first playable submission.

## 2. Existing canon — preserve

- [ ] Preserve Aurora Station and the Moon south-polar setting; do not add an unrelated planet, combat, or antagonist.
- [ ] Preserve the four cadets and roles: **Kai** (power), **Amara** (air), **Mei** (garden), **Rafi** (shielding/safe room).
- [ ] Preserve **Alo**, **Tara**, **Noor**, **Ferreira**, and **Rao**, and the name/meaning connection between Alo (light) and Noor (light).
- [ ] Preserve the crew-first order of priorities: **crew safety → station safety → Alo / science success**.
- [ ] Preserve Chapter 1's four named endings: **Golden Bloom, Bloom, Alo lost, Mission stopped**.
- [ ] Preserve the eight-chapter story sequence and the delayed reveal of Noor's identity in Chapter 5; do not prematurely reveal her identity or Ferreira's Expedition Zero history.
- [ ] Preserve the historical **2017 storm replay** in Chapter 1 and **2012 counterfactual replay** in Chapter 7; fictional 2046–2047 mission events are not historical observations.
- [ ] Preserve the 42-seed, vault, pollination, relay, and final-garden continuity already reconciled by the existing consistency report.

**Authority / consult before editing:** `docs/STORY_FINAL.md`, `docs/CAMPAIGN_SEASON1.md`, `docs/SCIENCE_AND_DATA.md`, `docs/GAMEPLAY_DESIGN_FINAL.md`, `game-design/02_COMPLETE_STORY.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/04_CHARACTER_BIBLE.md`, `game-design/21_STORY_CONSISTENCY_REPORT.md`.

## 3. Required changes — P0 (before judge-facing demo)

### STORY-01 — Lead with an engineering choice, not only exposition
**Problem:** A cinematic opening may delay the moment when the player understands this is a mission trainer.

**Update:** Within the first playable sequence, present a small, meaningful choice about resource allocation or equipment preparation. Introduce the characters through their responsibilities and responses to that decision, then establish Alo's emotional significance.

**Acceptance:**
- [ ] Player performs an observable station operation before a long uninterrupted exposition sequence.
- [ ] The choice has a visible downstream consequence, consistent with Chapter 1 mechanics.
- [ ] The opening can be explained to a judge in 30 seconds without needing later-chapter lore.

**Files:** `docs/STORY_FINAL.md`; `game-design/06_SCENE_SCRIPTS/` (Chapter 1 scenes); `game-design/11_DIALOGUE_MASTER.md`.

### STORY-02 — Sharpen role personalities through decisions
**Update:** Give each cadet one brief, recognizable tension related to the technical role: Kai weighs conserving energy against functionality; Amara emphasizes measurement quality; Mei argues for responsible crop support; Rafi evaluates shielding and risk. Resolve disagreement through evidence and collaboration rather than assigning one character to be consistently wrong.

**Acceptance:**
- [ ] All four cadets contribute distinct information or a relevant concern in Chapter 1.
- [ ] At least one short disagreement is resolved by a scientifically grounded player decision.
- [ ] Dialogue is concise and suitable for young learners; no character is mocked for safety concerns.

**Files:** `game-design/04_CHARACTER_BIBLE.md`; Chapter 1 scripts; `game-design/11_DIALOGUE_MASTER.md`.

### STORY-03 — Make the ethical stakes precise
**Update:** Resource scarcity can create tension around Alo, but the story must **never imply an optional trade of crew survival for a plant**. When resources compete, present crew safety as a hard constraint. For success, players seek a workable allocation within that constraint.

**Acceptance:**
- [ ] Every viable success ending keeps crew safety non-negotiable.
- [ ] Dialogue distinguishes responsible risk management from emotional attachment.
- [ ] An unsuccessful allocation is followed by a specific, constructive learning debrief rather than moral blame.

**Files:** `docs/STORY_FINAL.md`; `game-design/08_PUZZLE_DESIGNS.md` (P-02); endings/debrief scenes.

### STORY-04 — Label observed science, reconstructed science, and fiction
**Problem:** Claims like “everything you just lived through was real” can conflate authentic datasets with fictional future events or game assumptions.

**Update:** Rewrite overbroad debrief and pitch language to distinguish:
1. **Observed/historical:** traceable NASA/institutional records and publications.
2. **Computed/reconstructed:** derived Sun/Earth geometry or processed terrain/illumination under stated assumptions.
3. **Simulated/fictional:** Aurora Station, the cadets, simplified resources, time pressure, and future events.

**Proposed replacement idea:** “Inspired by real lunar science and historical space-weather data. You played a fictional training mission built from verified observations, reconstructed geometry, and clearly marked educational simulations.” Use exact wording only after scientific review.

**Acceptance:**
- [ ] No line describes the fictional 2046 station or player choices as a historical NASA event.
- [ ] 2017/2012 replays are clearly labelled, including the fictional setting into which they are replayed.
- [ ] Every prominent science claim used in dialogue, subtitles, pitch or debrief has a source or is labelled as a model assumption.
- [ ] No claim of computed/local geometry appears without verified processed data.

**Files:** `docs/STORY_FINAL.md` (30-second pitch and debrief); `docs/SCIENCE_AND_DATA.md`; `game-design/16_SCIENTIFIC_ACCURACY.md`; pitch script/subtitles.

### STORY-05 — Review site-specific sky and weather claims
**Update:** Audit statements about a **36-hour** darkness interval, visibility/“Earth-set,” the “240 days” illumination claim, solar storm arrivals, and shielding timelines. Earth visibility near the lunar pole depends on location, libration and terrain. Do not assert site-specific precision from generic descriptions.

**Acceptance:**
- [ ] For each site-specific claim, record coordinate, date/time, method, source, uncertainty, and reviewer.
- [ ] If not verified, present the interval or sequence as a **training scenario** or mark it as not yet validated, rather than a measured local history.
- [ ] The story still preserves “No Sun. No Earth.” as a dramatic *scenario outcome*, with appropriate educational explanation.

**Files:** `docs/SCIENCE_AND_DATA.md`; `game-design/16_SCIENTIFIC_ACCURACY.md`; Chapter 1 script and subtitles.

### STORY-06 — Deliver a complete Chapter 1 payoff and next-chapter hook
**Update:** Make the first-session arc understandable without Chapter 2: setup → forecast and choices → communication/radiation crisis → consequence → first light/debrief. After closure, reveal N.'s message as a short mystery hook, without disclosing the Chapter 5 identity.

**Acceptance:**
- [ ] Chapter 1 has a satisfying conclusion whether Alo blooms or not.
- [ ] No ending violates P-02 outcome logic or creates an accidental promise that later chapters are included in the hackathon build.
- [ ] Tara/Noor hook is short, emotionally clear, and consistent with existing continuity.

**Files:** `docs/STORY_FINAL.md`; Chapter 1 scenes and `game-design/07_MISSION_DESIGNS/` for M-0101/M-0102.

## 4. Recommended changes — P1 (after P0 is stable)

### STORY-07 — Reduce exposition and cognitive load
- [ ] Divide technical explanations into **one-line on-screen prompt** and **optional deeper science explanation**.
- [ ] Use early technical terms consistently (e.g., battery, air, shielding, growth chamber).
- [ ] Keep required cutscene/dialogue durations aligned with existing mission-time budget; avoid expanding Chapter 1 without a compensating cut.

### STORY-08 — Strengthen educational debriefs
- [ ] For each ending, explain **what happened**, **which decision mattered**, **why scientifically**, and **what to try differently**.
- [ ] Avoid framing plant loss as player failure or trivializing human safety.
- [ ] Include a specific “science evidence” entry and distinguish actual data from fictional animation.

### STORY-09 — Keep the eight-chapter arc focused on scientific action
- [ ] Each later-chapter reveal should accompany or follow a meaningful scientific/engineering task.
- [ ] Maintain delayed Noor reveal, cotton/seed lineage, route-and-relay constraints and 2012 replay labels.
- [ ] Keep the final garden and lighthouse/communications climax intact; do not add an unrelated final villain or twist.

### STORY-10 — Accessibility and cultural language checks
- [ ] Ensure subtitles for required dialogue, readable vocabulary for the target age band, and no information solely conveyed by color or audio.
- [ ] Review Bangla text (আলো, তারা, names and translated material) with a fluent reviewer; preserve meaning across language versions.
- [ ] Ensure the story works without prior knowledge of Bangladesh, orbital mechanics, or later episodes.

## 5. Change-control procedure

Before editing a locked line or historical claim:
1. Identify the canonical file and every dependent scene, dialogue index, subtitle and mission gate.
2. Record the proposed change and whether it affects **canon**, **science**, **mechanics**, or **presentation**.
3. Obtain story/science/gameplay review as applicable; do not silently modify numerical puzzle contracts.
4. Apply synchronized edits and rerun link/ID/chronology and worked-outcome checks.
5. Mark what is **designed**, **implemented**, **verified**, and **playtested** separately.

## 6. Definition of done

Story update is ready when all P0 items are checked with evidence, Chapter 1 has a coherent 30-second pitch and a complete playable-dialogue path, scientific claims are accurately labelled, and the existing consistency report's locked canon is preserved. **A written approval is not proof of working gameplay or NASA data integration.**

## 7. Suggested evidence log

Status words: **Designed** = written into the design docs (24 Oct 2026); nothing is implemented, verified in a build or playtested yet.

| ID | Owner | Status | Evidence link / commit | Reviewer |
|---|---|---|---|---|
| STORY-01 | TBD | Designed | SC-0101 commissioning choice + DL-0101-09/10/11, DL-0104-07/08/09 ([CHAPTER_01](game-design/06_SCENE_SCRIPTS/CHAPTER_01.md#sc-0101)); plaque walk cut to keep the time budget | — |
| STORY-02 | TBD | Designed | Shift-3 disagreement DL-0105-08 to 12; Rafi's "teased" trait removed ([STORY_FINAL](docs/STORY_FINAL.md#the-characters)) | — |
| STORY-03 | TBD | Designed | DL-0105-13 crew-first line; alarm panel's locked "Crew into Safe Room: required"; safe-only debrief alternatives ([UI/UX](game-design/13_UI_UX_DESIGN.md#chapter-1-debrief-game-07)) | — |
| STORY-04 | TBD | Designed, needs science review | "Everything was real" twist replaced by Observed/Computed/Simulated reveal (STORY_FINAL, README, SCIENCE_AND_DATA §B/§D, [16](game-design/16_SCIENTIFIC_ACCURACY.md#three-evidence-labels-story-04-game-06)); −52 °C and plant-immunity claims removed. **Not changed:** the already-published pitch video and its `.srt` still say "Real NASA data drives every mission" | — |
| STORY-05 | TBD | Register created; nothing verified | [Site-specific claim register](game-design/16_SCIENTIFIC_ACCURACY.md#site-specific-claim-verification-register-story-05); "240 days in a row" withdrawn; 36 h and Earth-set shown as *training scenario* | — |
| STORY-06 | TBD | Designed | Tara hook DL-0106-07 in Chapter 1; [ending closures](game-design/06_SCENE_SCRIPTS/CHAPTER_01.md#sc-0106-endings) for Alo lost and Mission stopped; Chapter 2 shown only as roadmap | — |

P1 items STORY-07 to 10 are not started. The Bangla debrief line in STORY_FINAL was rewritten and is flagged for the STORY-10 fluent review.

**Source basis:** User-supplied `STORY_FINAL(1).zip` and `game-design(1).zip`. Proposed requirements are reviewer recommendations, not pre-existing commitments or verified implementation results.
