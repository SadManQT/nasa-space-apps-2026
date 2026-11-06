# Last Light Academy — Master Plan

**For:** the five of us (Sadman, Ramim, Atik and two more teammates) and the AI each of us codes with.
**Status:** binding from 5 Nov 2026 (Sadman). Quality over quantity; no deadline sets priorities. Where this plan and an older plan disagree, this plan wins; the canon order in [PRODUCTION_HANDBOOK.md](../../PRODUCTION_HANDBOOK.md) §2 still decides story and numbers.

**How to use it:** type `continue(<your name>)` to your AI (§12). It reads your card in [team/](team/), takes your next tasks from the board ([BOARD.html](BOARD.html)) and works only inside the folders you own (§7). You do not need to read this whole file; your AI does.

---

## 1. The game we are making

**Last Light Academy** is a premium space adventure in which four cadets keep a lunar station, and the small plant they were trusted with, alive through a year at the Moon's south pole. Every challenge is a real problem astronauts solve: budgeting power and air for the dark, calibrating an instrument before trusting it, telling evidence from guesswork, isolating a fault, shielding from a solar storm, planning a drive with a safe return reserve.

**What the player should feel:** wonder (a photoreal Moon, a black sky, Earth on the horizon), responsibility (Alo, a mustard flower, and the crew depend on your plan), the click of understanding (you predicted, you tested, you were right — or you learned why not), and pride (you finish thinking like a junior astronaut).

**The core loop (every mission, doc 25 §6):** Brief → Prepare → Go → Investigate → Solve → Consequence → Report → Bridge to the next scene. Every puzzle runs **Learn** (a guided example that cannot fail) → **Apply** (real stakes) → **Twist** (one new constraint).

**Five pillars — every feature must serve at least one:**

| Pillar | In one line | It means in practice |
|---|---|---|
| A living thing depends on you | Stakes you care about | Alo, Tara and the crew react to your plan; plants never have faces, they show health through posture and colour |
| The science is the puzzle | Real NASA data drives real decisions | 32 data cards from real missions; numbers from [08_PUZZLE_DESIGNS](../../game-design/08_PUZZLE_DESIGNS.md); honest labels (measured, model, counterfactual) |
| Think like an astronaut | Predict → observe → explain → verify | "Try it" previews before you lock in; debriefs ask what you predicted and why |
| Beauty and calm | Photoreal environments, cel-shaded anime cast, quiet music | One hard low Sun, long shadows, no air haze; 60 fps; cinematic cutscenes |
| Never a lecture | Learn by doing; reading is optional | One goal on screen, hints you ask for, short animated explainers, no walls of text |

**Junior-astronaut competencies** (the curriculum, task M3-69). A player who finishes should be able to do all eight:

| # | Competency | Learned mainly in |
|---|---|---|
| C1 | Budget power, air, water and food with a reserve | Ch 1, 6, 8 |
| C2 | Measure with references and controls (calibration) | Ch 1, 4 |
| C3 | Separate evidence from inference; rebuild a timeline | Ch 2, 5 |
| C4 | Isolate a fault, test zero, restore and verify | Ch 3, 6, 7 |
| C5 | Read space weather and choose shielding (ALARA) | Ch 1, 7 |
| C6 | Navigate terrain with slope limits and a return reserve; line of sight | Ch 4, 8 |
| C7 | Keep living things and samples healthy (life cycles, pollination, sample integrity) | Ch 1–4 |
| C8 | Work as a crew: roles, shared plans, consent, split teams | All, strongest in 7–8 |

---

## 2. The story (canon — we keep it and make it shine)

**Decision:** we keep the canon story in [full-game-story/STORY_FULL.md](../../full-game-story/STORY_FULL.md) (8 chapters, 96 scenes). It is already fully voiced (388 lines), scored, and all 18 cutscenes exist. Rewriting it would throw away that work and the approved science fixes. We make it *feel* longer, more connected and more alive through the doc 25 systems: messages at every scene join, missions you play physically, the walkable Moon, story echoes of your own choices, and environmental clues. Real story changes stay possible, but only as proposals Sadman approves (they cost re-recording).

**From beginning to end:** April 2046 to April 2047. Four cadets run Aurora Station on Shackleton's rim: **Kai** (power and heat), **Amara** (atmosphere and measurement), **Mei** (horticulture) and **Rafi** (safety and field operations), with Commander **Ferreira** and flight controller **Rao** on Earth. The player *is* the crew. A drawer holds a seed packet marked "ALO" and "N.". The cadets plant **Alo** (purple-stemmed *Brassica rapa*) in the exterior chamber and **Tara** (green-stemmed) indoors, survive a 36-hour night and a replayed 2017 storm, and see Alo bloom. A stored message from N. says Alo needs a friend. They pollinate by hand, rebuild a 2034 recorder, and a moonquake leads them to **Expedition Zero's** abandoned annex: a garden that never flowered. Alo gives 42 seeds and dies naturally; Tara is harvested into a working stock. A rover trip to a cold trap brings back a vault whose lid says to ask Ferreira about Expedition Zero. Ferreira arrives and confesses she was the engineer who could not fix the radio; N. is **Dr Noor Rahman**, the living Bangladeshi botanist who founded the Academy. Cotton is planted. An eclipse, a counterfactual replay of the 2012 storm and Noor's last log follow, then the Earth link fails. In the finale three crew drive 120 km to the Malapert relay, replace its controller and prove both links — and only then does Noor speak live: "Hello, Aurora. This is Noor." At first light the shutter opens on a garden of Alo's descendants with the cotton alive.

**Two acts:**
- **Act One — Chapters 1–4: "Keep it alive."** Ends on the strongest cliffhanger in the story: the vault lid ("ask Commander Ferreira about Expedition Zero"), the fifth mug, and Ferreira's "I owe you the story." **Act One is our first release target** — four chapters, about 5.5 hours of story plus the Mission Trainer and the Moon trainer.
- **Act Two — Chapters 5–8: "Bring them home."** The truth about Expedition Zero, Noor, the red ring, the great storm and the lighthouse. Built after Act One passes its gate (§11), to the same bar.

Locked story facts that every task respects are in the handbook §4 (Earth-link cutoff at shift 4; Noor's name never before EX-CH05-S10; 42 = 12 + 30; English only; plants never have faces; no NASA logos).

---

## 3. Chapter roadmap

Every puzzle below answers the seven questions: **why** (story), **do** (what the player does), **fun** (what makes it challenging), **concept**, **experiment** (how the player learns by trying), **feedback** (how they know), **prepares** (what it sets up). Numbers are from [08](../../game-design/08_PUZZLE_DESIGNS.md); never change them in code.

### Chapter 1 — Night One (11–27 Apr 2046, ~75 min) · Act One

- **Places:** Commons LOC-01, Service Rooms LOC-02, Garden LOC-03, Safe Room LOC-04, mast courtyard LOC-06 (exterior view).
- **Story:** commissioning Aurora, rehearsing a safe stop without Earth, the ALO/N. packet, planting Alo and Tara, dated care, a seven-shift night with the Earth-link cutoff at shift 4 and the storm alarm at shift 5, first light and the first flower; N.'s message turns the story to Tara.
- **Cinematics:** CS-01 cold open (EX-CH01-S01), CS-02 (S09), CS-03 the shutter and the first flower (S12).
- **Mechanics introduced:** walking and E-interaction, the goal card and What now (H), the Mission Table shift loop, air maker / light / heat / water transfers, carrying and the STACK, the journal, care-round photos, mastery stars and endings, the first upgrade choice.
- **NASA data:** polar illumination (LRO), Sun and Earth positions (JPL Horizons), life-support rates (BVAD), the 2017 storm (DONKI, GOES-13), shielding (Clowdsley 2021), plant references (OSDR, Fast Plants).

| Puzzle | Why | Do | Fun | Concept | Experiment | Feedback | Prepares |
|---|---|---|---|---|---|---|---|
| **P-01 Commission and Plant** (M1-08) | The packet's seeds are irreplaceable; a bad probe would drown or dry them | Zero the probe on the dry cup, span it on the wet cup (offset +10), recheck, plant one seed per cassette, water to 40–60, label, seal | Small, tactile steps where a careless order wastes a seed | Instruments need references (calibration) | Read the cups before and after zeroing; see the offset vanish | Probe reading, a seed-safe indicator, Mei's comment | C2 for the cold-trap scan in Ch 4 |
| **P-02 Seven Shifts, One Night** (M1-09 done, M1-55 restyle) | The Sun sets in two shifts; power, air, water and shelter must last the night | Plan seven shifts at the Mission Table; lock each in; handle PUMP/STACK at shift 5 | Every gain costs something; the storm forces a hard trade | Storage limits, budgets, shielding | "Try it" forecasts before locking in; before→after bars | Endings (Bloom, Golden), stars, Alo's health | C1/C5 for Ch 6–7 |

**Chapter 1 work left (Act One, M1):** rooms from the kit M1-06 · terrain M1-34 · P-01 panel M1-08 · Mission Table restyle M1-55 · onboarding M1-18 · hint player M1-64 · messages system M1-56 and pack M1-57 · care round M1-49 · STACK carry M1-58 · explainers M1-59/M1-60/M1-63 · endings and debrief M1-19 · game feel M1-31 · first-impressions playtest M1-65 · QA M1-21 · learner playtest M1-22 · freeze M1-24.

### Chapter 2 — Be the Bee (30 Apr–6 May 2046, ~75 min) · Act One

- **Places:** Garden LOC-03, Airlock LOC-05, Commons LOC-01, Service Rooms LOC-02.
- **Story:** Tara flowers; there is no bee on the Moon, so the crew becomes the bee over seven care days; a 2034 recorder speaks; a cup trembles at 22:00 and the quake hits — straight into Chapter 3.
- **Cinematics:** CS-04 the quake (EX-CH02-S12).
- **Mechanics:** the pollination route through the airlock (each sealed run costs E1/A1 once), dated care, the Observed / Inferred / Unknown evidence board, the second upgrade choice.
- **NASA data:** Fast Plants, Mir *Brassica* seed-to-seed, DONKI 2017, Apollo shallow moonquakes.

| Puzzle | Why | Do | Fun | Concept | Experiment | Feedback | Prepares |
|---|---|---|---|---|---|---|---|
| **P-03 Alo Meets Tara** | Alo needs a partner to make seeds | Brush A carries Tara's pollen to Alo, clean brush B carries Alo's to Tara, through a sealed carrier and interlock; three runs | Contamination is easy; each run costs power and air | Pollination, cross-compatibility, clean technique | Try a dirty brush in Learn and see the run rejected | Pollen counters, a dated care strip with bee stamps | C7; the prediction pays off in Ch 4 |
| **P-04 Recorder Reconstruction** | A 2034 voice could explain the packet | Place three metadata tokens (A.DATE=2034-04, B.DEVICE=HORT-01, C.CHANNEL=ENGINEERING) | Clues conflict until you separate fact from guess | Provenance; observation vs inference | Move a token, see the board re-sort into Observed / Inferred / Unknown | The recorder plays; the journal files the evidence | C3 for Ch 5's timeline |

### Chapter 3 — Moonquake (6 May–21 Oct 2046, ~85 min) · Act One

- **Places:** Service Rooms LOC-02, Expedition Zero annex LOC-07, Garden LOC-03, Commons LOC-01.
- **Story:** the quake opens a leak; an independent gauge finds it; behind an N.R. hatch lies the 2034 annex with unflowered seedlings and a vault map; Alo's pods mature, 42 seeds are counted, 12 planted and 30 sealed, and Alo dies naturally; Tara's farewell; a montage to October; green stems appear among the purple.
- **Cinematics:** CS-05 the annex (EX-CH03-S07), CS-06 (S10).
- **Mechanics:** fault localisation and isolation, suited annex entry, the harvest ledger, sled carrying, the third upgrade choice.
- **NASA data:** Apollo shallow moonquakes, BVAD, Fast Plants, Mir *Brassica*, Chang'e-4 cotton.

| Puzzle | Why | Do | Fun | Concept | Experiment | Feedback | Prepares |
|---|---|---|---|---|---|---|---|
| **P-05 Find the Falling Pressure** | Air is leaking somewhere after the quake | Compare readings (MAIN 100/100, GARDEN 82/74, RETURN 100/100), verify the annex isolation after the aftershock, isolate GARDEN, clamp, reopen, five readings of 100 | Six candidates, four investigation phases; the obvious gauge is the broken one | Independent instruments; verification | Isolate a branch and watch which reading moves | Pressure trend, Amara's check-off, five green verifications | C4 for Ch 6–7 faults |
| **P-06 A Harvest With a Future** | Alo's seeds are the future garden | Confirm maturity, stop Alo's irrigation only, dry to ≤20, count 6 wells × 7 = 42, allocate 12 + 30, sleeve the petal | Patience and care; one wrong valve harms Tara | Life cycle; conserved inventory | Try the dry-down early in Learn and see seeds spoil | The ledger, the sleeved petal, the crew's quiet moment | C7; the 12 + 30 return in Ch 4–8 |

### Chapter 4 — Into the Cold Trap (21 Oct–12 Dec 2046, ~90 min) · Act One finale

- **Places:** Garden LOC-03, Garage and landing apron LOC-08, cold-trap approach LOC-09, vault shelf LOC-10, Commons LOC-01 — the first real drive across real LOLA terrain.
- **Story:** the descendants test the prediction (7 purple, 5 green); Rafi and Kai drive the rover while Mei and Amara hold the base; the safe ridge route, beacons, a calibrated ice scan, the vault, a staged warm-up, 12 specimens, the lid inscription; Ferreira's silence, the fifth mug, "I owe you the story."
- **Cinematics:** CS-07 (EX-CH04-S06).
- **Mechanics:** **the rover you drive**, EVA suit budget and scanner pulse, persistent beacons, base and rover ledgers, trailer cargo, the fourth upgrade choice.
- **NASA data:** VIPER slope limit, Diviner cold traps, LCROSS, Chandrayaan-1 M3 ice, Kaguya Shackleton floor, LOLA terrain.

| Puzzle | Why | Do | Fun | Concept | Experiment | Feedback | Prepares |
|---|---|---|---|---|---|---|---|
| **P-07 Survey and Return** | The vault lies in a cold trap; the rover must come back | Choose route B (100 − 30 − 30 = 40 ≥ 30 and 12° ≤ 15°), place three beacons, take dry reference 2, threshold 12, tag readings 18 and 19, seal one sample | Real terrain, a return reserve you can feel draining, a scan that lies without its control | Slope and return reserve; calibration with a negative control | The route planner shows slope profile and reserve before you commit | The reserve gauge, beacons on the map, a clean scan trace | C6/C2 for Ch 8's 120 km drive |
| **P-08 Recover Without Ruining** | 2034 specimens are fragile and cold | Probe, sleeve, cradle, mount, dry glovebox, three-stage warm-up, condensation check, 12 labels | Rushing fogs the samples | Condensation and sample integrity | Warm one stage too fast in Learn and watch fog form | Clear glass, 12 labels, the inscription revealed | C7; the vault lid hook into Act Two |

### Act Two — Chapters 5–8 (after Act One passes its gate)

| Ch | Title · dates · length | Story beat | Puzzles | New mechanics | Cinematics |
|---|---|---|---|---|---|
| 5 | Shooting Stars · 12–15 Dec 2046 · ~85 min | Ferreira lands and confesses; the evacuation timeline (all four returned); Noor identified with consent; cotton planted | P-09 Reconstruct the Departure (chronology from evidence) · P-10 Flashes and a Signature (real signal vs hot pixel) | Chronology board, flash classification, maintenance, message composer | CS-08, CS-09, CS-10 |
| 6 | The Red Ring · 12 Jan–14 Feb 2047 · ~85 min | Kai's fear of blackouts becomes a five-segment plan; the eclipse; a family call; feeder F2 | P-11 Protect the Small Light (energy budget for known darkness, 7 units) · P-12 Observe, Isolate, Restore (fault isolation) | Segment allocation board, protected-bus isolation, link windows | CS-11, CS-12 |
| 7 | The Great Storm · 14 Feb–8 Apr 2047 · ~105 min | A labelled 2012 counterfactual storm; five in the shelter; Noor's last log; the uplink fails at F-EXT | P-13 One Integrated Storm Plan · P-14 Three Waves and a Broken Link | Integrated multi-role plan, dosimeter run, uplink diagnosis, repeaters | CS-13 |
| 8 | The Lighthouse · 8–10 Apr 2047 · ~120 min | The 120 km drive to Malapert; controller swap; both links proved; Noor's live voice; first light and the garden | P-15 Two Teams, One Road (whole-mission provisioning) · P-16 The Link and the Living Garden (end-to-end network) | Split-team play, route planner, repeater service, dish aiming | CS-14 to CS-18 |

---

## 4. Visual and UI roadmap (AAA presentation)

**Done:** the clean HUD and design system (M1-54: one goal card, prompt on the object, toast, station strip only on change, What now on H, pause menu, no developer text, automated text test), the Journal v1 (M1-48), all cutscenes, the habitat kit (M1-05), the cast.

**The rules (doc 25 §1–§2, enforced by `game/tools/test_player_text.gd`):** one goal of at most 8 words plus a why; plain words, never codes; every number has a word and a scale; show only what matters now; the centre third stays clear while walking; every action answers back; text on dark glass, 4.5:1 contrast; motion 150–250 ms and reduced-motion aware; one look everywhere from `game/scripts/ui/ui_design.gd`.

| Area | What "premium" means here | Tasks (owner) |
|---|---|---|
| Rooms | Final kit rooms, lit, dressed and storytelling — no greybox anywhere a player walks | M1-06, M3-2R…4R (Sadman) |
| The Moon | Real LOLA terrain, photoreal regolith, one hard Sun, Earth at true size, streaming at 60 fps | M1-34, M3-60 (Sadman) · M1-36 (Atik) |
| Title and menus | Live 3D title view, animated transitions, Continue / New / Chapter select / Trainers / Settings | M1-18, M3-72 (Ramim) |
| Mission Table | Guided first shift, labelled toggles, before→after bars, night strip | M1-55 (Ramim) |
| Hints and learning | Three-level hint overlay with video | M1-64 (Ramim) · M1-59, M1-60, M1-63 (Sadman) |
| Messages and journal | Inbox, arrival toasts, threads, People and Science tabs | M1-56, M3-98 (Ramim) · M1-57 and chapter packs (Sadman, Ramim for Ch 2–4) |
| Progress | Cadet record, skills, achievements, curriculum | M3-64, M3-69, M3-72 (Ramim) |
| Game feel | Sounds, small animations, reward moments, count-up values | M1-31 (Ramim) |
| Settings | Controls, display, audio, accessibility, assist modes | M3-70 (Ramim) · saves M3-71 (Atik) |
| Moon play | EVA, carrying, markers, hazards, rover | M1-58, M3-61…65 (Atik) |
| Cinematics and audio | Voice, captions panel, music, sound | M1-61, M3-97 (Sadman) |

---

## 5. The learning system: hints, explainer videos and NASA data

1. **Ask, never interrupt.** Hints appear only when the player asks (H, or the Hint button on a puzzle panel). They pause the clock and never change an ending, a star or a reward.
2. **Three levels, one per request** (hint player, M1-64):
   - **Level 1 — Nudge:** one line spoken by the crew member whose job it is ("Kai: check the battery before the dark shifts"), with the relevant object highlighted in the world.
   - **Level 2 — Explainer video:** a 20–45 s animated explainer of the science behind the puzzle (the polar Sun, a proton-flux chart, why water shields, slope and reserve), captioned, ending on what it means for *this* decision. It never shows the answer.
   - **Level 3 — Worked method:** the method demonstrated on a different example (different numbers), so the player still solves their own.
3. **Two kinds of clips, two tools:**
   - **Science explainers** (animated diagrams, data stories) are made with **Claude Motion** — the Tweenkit plugin from the `claude-motion-skills` directory entry, installed in Sadman's Claude Code (M1-63 sets the house style and pipeline; M1-60, M3-68, M3-77 make the clips). If the plugin is not free, we do not buy it and the Godot pipeline below makes these too.
   - **How-to clips** (how to use a panel or a control) are recorded **in Godot from the game's own screens** (doc 25 §7, M1-59), so they always match what the player sees.
   - Both register in `game/resources/campaign/content/explainers.json` (id, path, length, captions, level); the hint player reads only that file.
4. **NASA data cards** (M1-30, done) open from every puzzle and debrief: what was measured, what the game computed, the limits. They stay honest: measured data verbatim, counterfactuals labelled.
5. **Learn by trying:** every decision has a "Try it" preview before "Lock in", so experimenting is safe and encouraged.
6. **Debrief** (M1-19): predict → observe → explain, the decision replay, and one sentence linking the result to the real mission it came from.
7. **Practice modes:** the Mission Trainer (M1-29, every puzzle as a 5–10 minute scenario from the title screen) and the Moon trainer (M3-67, free sorties on the real terrain).
8. **Measured learning:** the curriculum (M3-69) maps every puzzle to the competencies in §1; the cadet record shows them growing; the learner playtest (M1-22) measures it.

---

## 6. Technical architecture

**Engine:** Godot 4.7, Forward+ (Compatibility LODs kept). GDScript. GLB assets through LFS.

```
STORY_FULL.md ──build_catalog.py──▶ campaign_catalog.json (scenes, lines, choices; frozen hashes)
08 numbers ──▶ resources/campaign/profiles/*.json ──▶ simulation (pure functions: forecast = commit)
            route + gates per chapter (scripts/missions/) ──▶ campaign runtime (scripts/campaign/)
                     │                                   │
   puzzle logic + panels (scripts/puzzles/, ui/)    rooms (scripts/world/, scenes/campaign/rooms/) ◀── assets (game/assets/)
                     │                                   │
            HUD, menus, journal, hints (scripts/ui/) ── UiDesign tokens + ui_text.json
                     │
   save (scripts/save/, schema + story_log) · audio/cutscenes (presentation_media.json) · explainers.json · messages/chNN.json
```

**Contracts between owners** (so people work in parallel without touching each other's files):

| Contract | Provider → consumer | Shape |
|---|---|---|
| Puzzle panel | Ramim → Atik | `open(route, target_id, settings)`, signal `committed(result)`, like `mission_table_panel.gd`; logic stays pure in `scripts/puzzles/` |
| Gate wiring | Atik | the chapter's M task registers the panel in the route and gate catalog |
| Rooms | Sadman → Atik, Ramim | room scene + `room_contract.gd` focus targets (ids the missions use) |
| Explainers | Sadman → Ramim | `explainers.json` rows; the hint player plays them |
| Messages | Sadman/Ramim (content) → Ramim (system) | `messages/chNN.json`, format in doc 25 §5 |
| Saves | Atik → Ramim | read-only save metadata API in `scripts/save/` (M3-71) |
| Audio and cutscenes | Sadman | `presentation_media.json`; audio code in `scripts/audio/` |

**Rules that keep the code healthy:** gameplay values live in data, never hard-coded; the UI never computes campaign state (it reads a query and sends commands); every system has its own test in `game/tools/test_<system>.gd`; run tests only with `game/tools/run_tests.sh`; new input actions are registered in code by the system that uses them (no edits to `project.godot` except by Sadman); build new UI in code with UiDesign (fewer `.tscn` conflicts); never edit a scene file another member owns.

---

## 7. The team and who owns what

Shares are measured in effort points on the board (`python3 production/plan/board.py team`), not in task counts. Today: Sadman 39.7%, Ramim 29.5%, Atik 20.5%, member 4 5.5%, member 5 4.8% of the open work.

| Member | Share | Role | Owns (only they edit these) | Card |
|---|---|---|---|---|
| **Sadman** | 40% | Producer, art and media lead, integrator | Every asset and premium tool (Tripo, Meshy, ElevenLabs, Veo/Flow, Seedance, Claude Motion, Blender/Muse, Fable), rooms and environments, terrain and the Moon region, cutscenes, audio and its code, explainer videos, Chapter 1 and 5–8 message packs, `project.godot`, `presentation_media.json`, the handbook, docs, story, tools and the night shift; tags releases and signs chapter gates | [team/sadman.md](team/sadman.md) |
| **Ramim** | 30% | UI/UX and player-facing systems lead | Everything the player sees in 2D: HUD, menus, title, Mission Table, puzzle panels and puzzle logic, hint player, messages system, journal, settings, progression, achievements, upgrades UI, trainers, class mode; `ui_text.json`; Chapter 2–4 message packs | [team/ramim.md](team/ramim.md) |
| **Atik** | 20% | Gameplay runtime, Moon systems and builds | Missions and routes, campaign runtime, player controller, carrying, EVA, rover, markers and network, hazards, saves, loading, terrain streaming, export presets, the test runner, builds and performance | [team/atik.md](team/atik.md) |
| **member4** (name it, §12) | 5% | QA and playtest lead | `production/qa/chapters/`, `production/qa/playtests/` | [team/member4.md](team/member4.md) |
| **member5** (name it, §12) | 5% | Science, story and accessibility reviewer | `production/review/`, `production/qa/act1/`, `production/qa/full_campaign/`, `production/qa/dry_run/` | [team/member5.md](team/member5.md) |

Abu Sayem Mohammed Tanvir (`SayemTanvir`) chose the QA and playtest lead slot on 6 Nov 2026; use `continue(tanvir)`. The remaining `member5` reviewer slot is unnamed. The registered team also lists Md. Asif Iqbal and Shahariar Rahman Shanto. Historical art direction M1-32 and the rock kit M1-35 were Tanvir's; current folder ownership follows the table above.

**Why this split has the fewest merge conflicts:** each folder has exactly one owner, so two people never edit the same file. Chapters move *through* owners (assets → rooms → puzzles → missions → QA) instead of one person editing everything for a chapter. `board.py check` fails if two members' open tasks own the same folder. Shared files are handled safely: the board (one field per line, merges itself), the AI log and the asset registry (`merge=union` in `.gitattributes`: both sides' new rows are kept), and the handbook (only Sadman edits it; everyone else puts status in their task evidence). When you need a change in someone else's folder, you do not make it — you file a task for them with `board.py add`.

---

## 8. Dependencies: what waits for what

**Independent tracks (start today, in parallel):**
- Sadman: rooms M1-06, terrain M1-34, Claude Motion pipeline M1-63, Chapter 1 assets M1-07, messages M1-57, Chapter 2–4 assets.
- Ramim: P-01 panel M1-08, onboarding M1-18, Mission Table M1-55, hint player M1-64, messages system M1-56, endings and debrief M1-19, goal text M1-62.
- Atik: care round M1-49, loading M1-53, save slots M3-71, then terrain streaming M1-36 (after M1-34) and EVA M3-61.
- Tanvir: first-impressions playtest M1-65. member5: the challenge statement M0-12, then the science fact-check M3-75 (after M1-57).

**Per-chapter flow:** assets (Sadman) → rooms (Sadman) → puzzle panels (Ramim; can start on greybox) → missions and wiring (Atik) → messages (Sadman / Ramim) and explainers (Sadman) → chapter QA (member4 or member5) → gate sign-off (Sadman). The board encodes every one of these as `deps`; `board.py take` only hands out ready tasks.

**Cross-owner requests:** you never edit another member's folder. File a task: `python3 production/plan/board.py add --milestone M1 --for atik --title "Expose the care-round photo ids" --prompt "<what, why, acceptance>" --paths game/scripts/campaign/ --by "Ramim/codex"`, push, and carry on with something else. Owners take filed tasks in their normal `continue`.

---

## 9. Development order

1. **Phase 0 — Team setup (done, 5 Nov):** ownership, shares, the board tools, this plan, `continue(<name>)`.
2. **Phase 1 — Chapter 1 to release quality (M1).** Everything in §3's Chapter 1 list, ending with QA M1-21, the learner playtest M1-22 and the freeze M1-24. Chapter 1 is our quality template: when it passes the gate, every later chapter copies its patterns.
3. **Phase 2 — The Moon journey foundation (M1/M3, parallel with Phase 1 where owners are free):** terrain M1-34 → M1-36, EVA M3-61, Moon region M3-60, markers M3-62, hazards M3-65, rover M3-63, Moon trainer M3-67, curriculum and cadet record M3-64/M3-69.
4. **Phase 3 — Chapters 2, 3, 4 (M3), in order,** each through its gate before the next is called done.
5. **Phase 4 — Act One release candidate:** full QA M3-74 and the RC build M3-73.
6. **Phase 5 — Act Two, Chapters 5–8 (M4),** same pipeline and gates, then full-campaign QA M3-92 and builds M3-93.

The hackathon package (M2: videos, project page, dry run) stays on Sadman's and member4's lists, but it no longer sets priorities.

---

## 10. Testing and polishing

- **Every task:** `game/tools/run_tests.sh` green (paste the last line), screenshots of every changed screen in `production/qa/evidence/<task>_*.png`, and the task's own test. Never trust a bare Godot exit code.
- **Text and clarity:** `test_player_text.gd` fails on developer words, codes or a covered centre; extend it when you add a screen (Mission Table in M1-55; Chapters 2–8 in M1-62).
- **Independent review:** before marking a non-trivial task done, ask a second AI (a different one if you can) to review the diff against the task's acceptance; fix what it finds. Sadman's night shift does this automatically.
- **Performance:** 60 fps in every room on the reference Mac; loading behind the animated card; `game/tools/perf_probe.gd` (M1-23).
- **Animation defects:** check every new animation in a capture: no foot sliding, no T-pose frames, no clipping through the coverall, lip sync on voiced lines.
- **Visual consistency:** [ART_BIBLE](../ART_BIBLE.md) §2–3; Moon science rules (black sky, no airborne sound, dust falls straight down).
- **Playtests:** the first-impressions test (M1-65) now, the learner playtest (M1-22, 5+ players) after Chapter 1 QA, and a fresh-player test for every chapter gate. A bug always becomes a board task for the owner of the folder.

---

## 11. Completion criteria

### The chapter gate (every item PASS, recorded in `production/qa/chapters/chNN/gate.md`, signed by Sadman)

| Area | PASS means |
|---|---|
| Story | Every scene plays in order; every join in doc 24 §2.9 has its bridge and at least 2 messages; canon text word for word |
| Gameplay | Every mission follows Brief → … → Bridge; every puzzle has Learn, Apply and Twist and takes 8–15 min first time; retry from checkpoint works |
| Science | Every number matches 08; every claim checked against its source (member5's review); data cards open from every puzzle |
| UI clarity | `test_player_text.gd` passes for the chapter; a fresh player always knows the goal (playtest) |
| Visuals | No greybox in any walkable space; lighting final; no missing or pink materials; the art bible respected |
| Animation | No T-poses, sliding or clipping in captures; lip sync on every voiced line |
| Audio | Every line voiced or captioned; music cues and effects present; captions on a panel |
| Cinematics | The chapter's cutscenes play in place, skippable, with captions |
| Performance | 60 fps in every room and on terrain on the reference Mac; no load stalls over 2 s without the loading card |
| Stability | Two complete playthroughs with no crash; save, quit and continue at three points restore exactly |
| Accessibility | Large text, captions, reduced motion and timer-free play all work through the chapter |
| Learning | The chapter's competencies (§1) appear in the debrief and the curriculum; hints at all three levels exist for both puzzles |
| Fun | At least 3 fresh players finish without outside help and rate it 4/5 or better for "I want to keep playing" |

### Act One release (Chapters 1–4)

All four chapter gates PASS; the Act One QA (M3-74) has no open P0/P1 finding; the RC build (M3-73) passes a 2-hour soak on Windows and macOS; title, Chapter select, both trainers, settings, saves and achievements work; Sadman tags the release.

---

## 12. continue(<name>): how each of us works

Type **`continue(<your name>)`** to your AI (for example `continue(ramim)`). The AI then follows [GO_NEXT.md](GO_NEXT.md) §0:

1. `git pull --rebase`.
2. Finds you in `python3 production/plan/board.py team`. If you are new and a slot is still called member4 or member5, it names that slot after you (`board.py rename-member member4 <name> --name "<full name>"`), commits and pushes. Member 4 is the QA and playtest lead, member 5 the science and accessibility reviewer — say which you prefer.
3. Reads your card in [team/](team/) and the folders you own.
4. Finishes anything you already have in progress (`board.py mine --by "<Name>/<AI>"`), then claims up to 5 ready tasks: `board.py take --by "<Name>/<AI>" --count 5`, and pushes the claim.
5. Does each task: reads the prompt and its read-first files, edits **only your folders**, runs the tests, takes screenshots, gets a second-AI review, logs AI use, marks it done with evidence, commits under **your own GitHub account** (no AI co-author lines) and pushes — one task at a time.
6. Tells you what only a human can do (`board.py list --member <name> --tool human --status todo`).
7. Stops after about 8 tasks, or when nothing is ready, and tells you what it finished and what is next. Never leaves claims behind.

**Progress tracking:** the board is the truth ([BOARD.html](BOARD.html) in a browser); `board.py team` shows everyone's share; `board.py stale` lists forgotten claims. Sadman's night shift works only Sadman's tasks.
