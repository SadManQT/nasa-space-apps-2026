# 25 — Player clarity, professional UI and the Moon journey

**Status: binding.** Sadman, 5 November 2026, after playing the 5 November build: the game screen is "super confusing"; a player must understand everything they are doing; the game should play like *Death Stranding* in every play style, as an RPG Moon built with Claude Fable; the UI must be "super clean like a professional AAA game"; puzzles and missions must be long enough; every scene must connect to the next with lots of text messages; short motion videos may explain things; then build the whole game.

**Authority.** The story text ([STORY_FULL.md](../full-game-story/STORY_FULL.md)), the numbers ([08](08_PUZZLE_DESIGNS.md)) and the scene joins ([24](24_NARRATIVE_REVISION.md) §2.9) do not change. This document governs what the player sees and does: presentation, onboarding, messages, traversal, progression and mission shape. Where [GAMEPLAY_DESIGN_FINAL.md](../docs/GAMEPLAY_DESIGN_FINAL.md) §3 or §5 disagrees, this document wins, **except** its accessibility rules, which are kept here word for word in spirit: no platforming skill gate, no rapid repeated presses, no timed actions in Family Mode, a hold or assisted alternative to every dexterity task, and no secret spending of base oxygen or battery.

**Originality guard.** The journey borrows *mechanics* from the traversal-and-delivery genre (route planning on real terrain, care for what you carry, infrastructure you build that later carries people's voices — already promised in [22](22_PUZZLE_CLUE_DESIGN.md) T5). It takes no names, invented terms, characters, creatures, art, music, interface look or level layouts from any existing game. Our words come from real lunar operations: EVA, sortie, traverse, payload, survey marker, fixed line, relay, return reserve.

---

## 0. What confused the player (5 November build)

From [M1-09_hud_plan_button.png](../production/qa/evidence/M1-09_hud_plan_button.png) and [M1-09_shift1_cards.png](../production/qa/evidence/M1-09_shift1_cards.png):

1. **Developer language on screen:** "EX-CH01-S07", "P-02 preview", "role constraints", "stage", "commit", "physical operations", "LOCAL LIVE", "Acknowledge line".
2. **Variables instead of words:** "E 14/20", "A 6/10 · Wall water W 0", "S 0/6 · Exposure Z 0", "C 8/10 · Rations R 12d", "E0 · air +0".
3. **Everything at once:** four status cards, an objective block, a controls block, an operations list and a dialogue box cover about 70% of the screen while the player is just walking.
4. **An objective nobody can parse:** "Commit daylight shift 1 after role acknowledgement and stage, but do not yet commit, shift 2."
5. **A spreadsheet instead of a decision:** the Mission Table shows twelve numbers, nine buttons, four crew rule lists and no worked example; locked crew cards say "Not yet available".
6. **No "why":** nothing tells a new player why air or the shelter water matters tonight.
7. **Text floating over the 3D scene** with no backing panel.
8. **Unfinished rooms** (flat walls) — fixed by the habitat kit (M1-05) and room assembly (M1-06).

---

## 1. Ten clarity rules (every screen, every chapter)

1. **One goal.** In free movement the screen shows one goal: verb + thing + place, at most 8 words ("Plan the first shift at the Mission Table"). Under it one *why* line, at most 12 words ("The Sun sets in two shifts; the battery must last").
2. **Plain words.** No scene IDs, puzzle codes, single-letter variables or engineering verbs in player text (§1.1). Developer IDs appear only in debug builds behind F10.
3. **Every number means something.** A value always has a word and a scale, and when it matters a meaning: "Battery 14 of 20 · enough for 2 dark shifts".
4. **Show only what matters now.** A panel appears the first time it matters, with one gentle "new" pulse, and hides when not needed. Locked things are not shown at all.
5. **Teach, let them do it, then trust them.** Each new mechanic gets a first-time card (title, one-line purpose, at most 3 steps, an explainer clip from §7), then one guided use with the exact control highlighted, then free use. Never test a rule before teaching it (22 T6).
6. **"What now?" is always one key away.** H (controller: View) opens What Now: the goal, the why, where (map marker), the last two messages and the next hint. Hints never change outcomes.
7. **The world shows the way.** A goal marker in the world with distance in metres (fades within 3 m), a floor light strip the first time a route is new, and a prompt on the object itself ("E · Read Kai's note").
8. **Every action answers back.** A sound, a small animation and a one-line result ("Air maker set to Low: +1 air, −1 battery each shift").
9. **Reading is optional; understanding is not.** Story and lore can be skipped; the goal and the why cannot be missed. Dialogue has Next and Auto; messages never block play.
10. **Readable everywhere.** Text always sits on a panel with at least 4.5:1 contrast; 18 px minimum at 1080p; large-text mode; colour is never the only signal; button glyphs follow the active device.

### 1.1 Player words (display strings only; code and data names stay)

| Today | The player sees |
|---|---|
| commit / commit shift | Lock in / Lock in shift |
| stage (a shift) | Prepare |
| role constraints, role cards | Crew notes |
| Acknowledge line | Next |
| physical operations | Jobs here |
| LOCAL LIVE | the speaker's name only ("Earth link" or "Radio" when not in the room) |
| E, Energy | Battery |
| A | Air |
| W, Wall water | Water in the shelter wall |
| K, Crates | Supplies in the shelter wall |
| S, Shelter | Storm shelter |
| Z, Exposure | Radiation dose |
| C, Crops | Garden health |
| R, Rations | Food (days) |
| P-02 | Seven Shifts (the night plan) — never the code |
| EX-CH01-S07 | hidden; the chapter name and the story date only |
| Preview | Try it (nothing changes yet) |
| Pin as plan A | Save as Plan A (in the More menu) |

---

## 2. A clean, professional interface

### 2.1 Design system (one look for every screen)

- **Type:** the existing UI font family in four sizes only (1080p): 40 titles, 28 headings, 20 body, 16 captions; all scale with large text. Sentence case. Lines at most 60 characters.
- **Colour:** [ART_BIBLE](../production/ART_BIBLE.md) §3 palette. One accent means "do this now"; one amber for caution; one red for danger; everything else neutral. No colour-only meaning.
- **Panels:** dark glass (deep navy at 80%, light blur), 12 px radius, 1 px light edge. No boxes inside boxes. At most two panel layers on screen.
- **Layout:** 8 px grid; 64 px safe margin at 1080p; panels anchor to edges and corners. **The centre third of the screen stays clear while the player moves.**
- **Motion:** 150–250 ms ease-out to show or hide; values count up or down; nothing blinks more than twice; honours reduced motion.
- **Icons:** one line-icon set at 24 px, always with a word the first time it appears.
- **Sound:** one soft focus tick, one confirm, one caution tone, from the existing effects.
- **Diegetic first:** suit readouts live on the visor and wrist display, rover readouts on the cab dashboard, station values on station screens. The flat HUD carries only the goal, prompts and messages.

### 2.2 What is on screen, and when

| State | On screen |
|---|---|
| Walking in the station | Goal card (top left, 2 lines) · prompt next to the object in reach · a message toast when one arrives (top right, 5 s) · the station strip **only** when a value changes or runs low (top right, compact) |
| Dialogue | Speaker and line (bottom centre, at most 2 lines) · Next / Auto · the goal card dims |
| Instrument or panel | The panel in focus, the world blurred behind, one exit key shown |
| Mission Table | §3 layout |
| EVA | Visor: suit budget ring (oxygen, power, cooling) bottom right with the return-reserve tick · scanner overlay while pulsing · goal card |
| Rover | Cab dashboard: speed, slope against the limit, battery against the reserve, the planned route |
| Pause | Resume · What now · Messages · Journal · Map · Settings · Save and quit |

The four always-on status cards, the operations list and the controls block leave the HUD. Controls appear as prompts when needed and in Settings → Controls.

### 2.3 Title and menus

- **Title:** Continue (when a save exists) · New campaign · Moon trainer (§4.7) · Settings · Science and sources · Credits · Quit, over a live 3D view: the station on the ridge, Earth low on the horizon.
- **Settings:** Gameplay (assist mode), Controls, Display, Audio, Accessibility. English only.
- **Assist modes** (chosen at New campaign, changeable any time): **Story** (every assist, no timers), **Cadet** (default: assisted balance and driving, generous timers), **Expedition** (manual balance, real timers). Family and Class modes stay as defined.

---

## 3. The Mission Table made simple (presentation only; P-02 numbers unchanged)

- **A guided first shift** (shift 1 only), three steps, each highlighting one row with a one-sentence consequence: set the air maker; set the garden light; *Try it*, then *Lock in shift*.
- **Rows appear when their information arrives**, following 08's schedule (air and light first; the shelter water when Rafi's outlook arrives; heat at the first dark shift). Crew who have not arrived are not shown.
- **Choices are labelled toggles with icons:** "Air maker: Off · Low · High".
- **The forecast is before → after bars** for Battery, Air, Alo, Tara, Garden, Storm shelter and Radiation dose, with an arrow and one sentence for the biggest change ("Battery drops to 12 — enough for 1 dark shift").
- **Crew notes:** one card per arrived crew member — portrait, role, one key fact, "More" for the full note; sharing is one click and the card then reads "Shared".
- **The night at a glance:** a strip of 7 shift cells with Sun or dark icons and the known events (drill, Earth-link cutoff, storm outlook, sunrise).
- **Buttons:** Try it · Lock in shift (Space) · Close (Esc). "Save as Plan A" moves to a More menu.
- The same simulation, preview function and numbers as M1-09 and 08.

---

## 4. The Moon you can walk — an RPG Moon, built with Fable

### 4.1 The region

- **Real ground:** the LOLA south-pole elevation data (M1-34), streamed in Godot (M1-36), around the Shackleton–de Gerlache connecting ridge: the mast courtyard (LOC-06), the rover garage and landing apron (LOC-08), Expedition Zero's annex (LOC-07), the surveyed cold-trap approach (LOC-09) and the vault shelf (LOC-10). The Malapert relay road (LOC-11) and summit (LOC-12) are rover journeys in chapters 4 and 8, streamed in segments.
- **Look (5 November lock):** photoreal regolith, one hard low Sun, black sky, Earth near the horizon at true size, long shadows, no air haze; the cast stays cel-shaded.
- **Places worth visiting**, each with a reason (a job, a clue, a view or a measurement): masts and solar arrays, the landing pad, Expedition Zero's old survey markers, a boulder field, a crater-rim lookout, the cold-trap edge, relay sites.

### 4.2 Walking on the Moon (EVA)

- **Suit budget:** oxygen, power (heaters and lights) and cooling, with the estimated cost and the **return reserve** shown on the route card *before* leaving (22 T4). Walking inside the station costs nothing.
- **Reading the ground:** hold F to pulse the scanner. Slope bands carry a number and a pattern (flat · careful · steep · no-go), plus boulders, soft regolith and cold shadow.
- **Footing and load:** slopes in the careful band slow the walk; a heavy or tall payload sways; Q/E (controller triggers) lean to keep balance, and assisted modes balance for you. A slip costs time and may scuff the payload; it never ends a mission and never kills.
- **Lunar movement:** longer strides and a bounding gait on flat ground; dust thrown up falls straight back down (no billowing clouds; Moon science rules in ART_BIBLE §2).
- **Light:** the headlamp in shadow; the Sun's direction matters for heat and for seeing.

### 4.3 Payloads (carrying)

- Every payload has a mass, a size, handling needs (fragile, sealed, keep cold) and a destination. Carry places: hands (1), back frame (up to 3 small), sled (from chapter 3), rover trailer (from chapter 4).
- The visor shows the load and its weight; anything over capacity is refused *before* pickup, with the reason.
- **Chapter 1's STACK** stays exactly as 08 defines it: four supply bundles snap into outlined bunk slots in 30 seconds, with assisted input, and no falling-crate physics.
- **Delivery:** set the payload in its marked place; its condition is checked against its handling needs.

### 4.4 Things you build stay (the network)

- Survey markers (the chapter 4 beacons, already canon), fixed lines on steep stretches, path lights and relay repeaters (chapters 7–8).
- They are made from payloads you carry, they stay in the save, and they appear on later trips, on the map and in the route planner (24 N1: chapter 4 beacon positions return as a layer on the chapter 8 route map).
- **Coverage map:** relay links drawn as lines. A new link can bring messages (the Earth desk, the archive). The finale's live voice arrives over the network the player built (canon: P-16 dual-link verification).

### 4.5 The rover

- VIPER-class slope limit from the fixture (`viper_slope_limit`), battery with a return reserve, trailer payloads, and readouts on the cab dashboard. Assisted driving stays inside the slope limit; Expedition mode only warns.
- **Route planner:** pick waypoints on the map; see the slope profile, distance, time, battery and reserve before confirming.

### 4.6 The RPG layer

- **Cadet record:** every sortie and job ends with a report card — time against plan, payload condition, care, science value, reserve kept. These are training grades; they never lock the story.
- **Cadet skills**, earned by doing and shown on the record, three ranks each: Navigation (route hints, marker capacity), Handling (sway tolerance, fragile care), Life support (better suit-budget technique), Repair (fault-isolation hints), Observation (scanner range). Each rank gives a small visible benefit and a line from the crew member who taught it.
- **Gear:** suit upgrades and tools come from the existing upgrade choices (M3-xU, the 128 profiles; Dust Shield and Whipple are canon), equipped in loadout slots before an EVA with a weight limit — real trade-offs.
- **Jobs board** (station terminal): optional work between story missions — deliveries (spare parts to the masts), surveys (mark a new route), maintenance (dust the arrays), science (a cold sample run). Each has a sender and a reason in Messages, and pays in skill progress and crew notes, never in story.
- **Rest:** the bunks in the Safe Room (LOC-04) — save, read messages, look through the Alo and Tara photos and the cadet record.
- **People:** relationships already follow story choices (24 §5); message threads deepen them; job senders are the crew.

### 4.7 Moon trainer

A title-menu mode (built with M1-29 Mission Trainer) with free training sorties on the real terrain from day one: walking, the scanner, carrying, markers and the rover, with no story spoilers. The Chapter 1 demo therefore has a playable Moon without changing canon.

---

## 5. Messages that connect every scene

- **Messages** (pause menu and key M): threads for the Crew (Kai, Amara, Mei, Rafi), the Commander, the Earth desk (Rao), the Academy (training notes) and the Archive (Expedition Zero records, as found).
- **At every join** in 24 §2.9 (100 joins): **at least 2 messages** — what just happened and why it matters; what comes next and where — plus optional character and lore messages. Missions, deliveries and jobs send their own (briefing, thanks, report).
- **Arrival:** a small toast ("New message · Mei: Tara opened"), never during dialogue; reading is optional; important messages also become the goal card's next step.
- **Writing:** English only; at most 60 words each; in the speaker's voice (04 character bible); dated in story time (UTC); science claims follow 24 §2.12; never a future name — "Noor" and "Rahman" never appear before `EX-CH05-S10` (until then she is N.).
- **Data:** one file per chapter, `game/resources/campaign/content/messages/ch01.json` … `ch08.json`:

```json
{"chapter": 1, "messages": [
  {"id": "MSG-CH01-001", "thread": "crew", "sender": "Rafi", "story_time": "2046-04-11T21:40Z",
   "unlock": {"on": "scene_exit", "id": "EX-CH01-S01"}, "join": "CH01 S01→S02",
   "subject": "Name tokens", "body": "…at most 60 words…", "goal": false}
]}
```

  `unlock.on` is one of `scene_enter`, `scene_exit`, `mission_done`, `job_done`, `found`. `join` copies the join label from 24 §2.9 when the message carries that join.
- **Volume:** about 300–400 messages across the campaign; Chapter 1 at least 30.

---

## 6. Missions and puzzles: long, clear, never padded

- **Every story mission has the same shape:** Brief (messages and goal) → Prepare (loadout, route, checklist) → Go (EVA, drive or a route through the station) → Investigate (clues, 22) → Solve (the puzzle) → Consequence (story beat or cutscene) → Report (report card and messages) → Bridge (the join's messages lead to the next scene).
- **Every puzzle runs in three stages** (22 T6/T7): Learn (a guided example that cannot fail), Apply (real stakes), Twist (one new constraint). 22's investigation, deduction, escalation and hint tiers stay.
- **First-time length targets:** a puzzle 8–15 minutes; a story mission 15–30 minutes; each chapter at least its 24 time (75, 75, 85, 90, 85, 85, 105, 120 minutes; about 12 hours in all), plus optional jobs.
- **Long is not padded:** every minute is a decision, a discovery, a journey or an earned quiet beat. No errand without a reason in Messages; no repeat without a twist.

---

## 7. Explainer clips (short motion videos)

- **8–20 seconds,** silent with captions, made **in Godot from the game's own screens and 3D** (scripted inputs + arrows, rings and labels; Movie Maker → `.ogv` with [ogv_writer.gd](../production/tools/ogv_writer.gd); 1152×648 at 24 fps like the cutscenes), so a clip always matches what the player sees. One spec file per clip in `production/explainers/`, so clips rebuild when a screen changes.
- Shown in the first-time card for each mechanic and replayable from Journal → How to; always skippable.
- **Chapter 1:** moving and looking; using things (E); the goal card and What now (H); the station strip; Messages; the Mission Table in three steps; locking in a shift; carrying and stacking supplies; the care-round photo; the evidence board.
- **Chapters 2–8, one per new mechanic:** the pollination route; reading a recorder's history; isolating a fault with a reference gauge; the harvest ledger; the scanner pulse and slopes; markers and fixed lines; the rover and the return reserve; classifying an impact flash; the energy budget for darkness; the storm shelter run and the dosimeter; repeaters and the coverage map; replacing the controller and checking both links.

---

## 8. How we know it works (acceptance)

1. **No developer language on screen:** an automated test walks every HUD and panel state and fails on any visible text matching `EX-CH\d`, `\bP-\d\d\b`, a lone variable letter with a number (`\b[EAWKSZCRH] ?\d`), or the words *commit, stage, acknowledge, role constraint, operation(s)*.
2. **Clear centre:** in free movement no panel except the goal card, a prompt and a toast is visible, and none covers the centre third of the screen (automated).
3. **Teaching coverage:** every mechanic in the registry has a first-time card, a clip and a guided first use (automated).
4. **Messages:** every 24 §2.9 join has at least 2 messages; IDs are unique; unlock scene IDs exist; bodies are at most 60 words; English only; no "Noor" or "Rahman" before `EX-CH05-S10` (automated, `production/tools/check_messages.py` plus a Godot test).
5. **Five-second test** at 10 checkpoints in Chapter 1: a screenshot alone shows what to do and why (QA screenshots in the evidence).
6. **Length:** first-time play times per mission and chapter are logged in QA and meet §6.
7. **Learner playtest** (M1-22): at least 4 of 5 players can say what they are doing and why at each checkpoint.

---

## 9. Board tasks created from this document (5 November)

| Task | Lane | What |
|---|---|---|
| M1-54 | claude (Fable) | Clean HUD and the UI design system (§1–§2) |
| M1-55 | claude (Fable) | Mission Table made simple (§3) |
| M1-56 | codex | Messages: inbox, toasts, unlocks, validator (§5) |
| M1-57 | claude (Fable) | Chapter 1 messages (§5) |
| M1-58 | codex | Payload carrying and the STACK bundles (§4.3) |
| M1-59 | antigravity | Explainer-clip pipeline, Chapter 1 clips, first-time cards, Journal How to (§7) |
| M3-60 | claude (Fable) | The Moon region on real terrain (§4.1) |
| M3-61 | codex | EVA: suit budget, scanner pulse, footing and load, assists (§4.2) |
| M3-62 | codex | Markers, fixed lines, lights, repeaters and the coverage map (§4.4) |
| M3-63 | codex | Rover and route planner (§4.5) |
| M3-64 | claude (Fable) | RPG layer: cadet record, skills, gear loadout, jobs board, rest (§4.6) |
| M3-65 | codex | Readable hazards: quake, cold, impact flashes, darkness, storm shelter run (§4.2, §6) |
| M3-66 | antigravity | Explainer clips for every chapter 2–8 mechanic (§7) |
| M3-67 | antigravity | Moon trainer mode (§4.7) |
| M3-2T … M3-8T | claude (Fable) | Messages for chapters 2–8 (§5) |

Existing tasks gain this document: M1-18 (first five minutes, now Fable), M1-21 (Chapter 1 QA waits for M1-54…M1-59), M1-29, M1-31, M3-90, every chapter's puzzles, missions and QA (missions wait for the journey systems their chapter uses), and M3-92.
