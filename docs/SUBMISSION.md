# NASA project page: text ready to paste

Team **The Last BrainCell** · Dhaka, Bangladesh · Challenge: **Build a Junior Astronaut Mission Trainer** · Project: **Last Light Academy**

One section per field of the project page on spaceappschallenge.org, in the order the Bangladesh Participants Guide lists them ([competition-rules.md](competition-rules.md) §C). Paste the text under each heading. Written 7 November 2026 (board M2-02) and updated 12 November 2026 to the repository as it stands that day; every number comes from the files named in the section.

**Before pasting (M2-10), replace or check:**
- `[link after upload, M2-06 / M2-08]`: the YouTube links of the 240-second video (M2-06) and the 30-second video (M2-08).
- `[metric from M1-22 when the playtest runs]`: the learner playtest numbers. Delete the sentence if M1-22 has not run; never estimate.
- Items marked **[status on 12 Nov]**: the release build for judging (M3-93). Change "in progress" to "built" only when the board says `done`. Class mode (M1-37) is done.
- Open every link in a private window: everything must open with no login.

---

## 1. High-Level Summary

Last Light Academy is a free, open-source 3D mission trainer for learners aged 10 to 15. Players run Aurora Station, an outpost at the Moon's south pole, through a 36-hour lunar night. At the Mission Table they plan seven 7.2-hour shifts, trading off the four demands the challenge names: life support (the air tank), radiation shielding (a water wall), power (a battery of "sun-drops") and food production (the garden and Alo, a small mustard plant). Every plan is previewed before it is locked in, and the station then lives with it: a blackout, a storm dose, a wilting plant or a first bloom. The trade-offs are real ones. The water that shields the crew from a replay of the 10 September 2017 solar storm is the water Alo drinks, and the power that keeps the crew warm also makes their air.

The game is NASA-data-first. Its key numbers come from 29 NASA and partner sources bundled offline: NASA DONKI space-weather records, NASA's Life Support Baseline Values (BVAD), LRO LOLA terrain and illumination, JPL Horizons Sun and Earth positions, LRO CRaTER radiation dose and more. In-game Data Cards show the source behind each number and label it as measured, computed or a training assumption. All 8 chapters, 32 missions and 96 scenes across one Moon year are playable, with 16 interactive mission puzzles and 19 narrated science explainers.

- **240-second video:** [link after upload, M2-06 / M2-08]
- **GitHub repository:** https://github.com/SadManQT/nasa-space-apps-2026

---

## 2. Project Demo

- **30-second video (English on-screen text):** [link after upload, M2-08] (file: `production/pitch/LastLightAcademy_Video3_30s.mp4`)
- **Seven-slide deck (NASA's accepted alternative, English):** https://github.com/SadManQT/nasa-space-apps-2026/blob/main/production/video/deck.pdf

---

## 3. Final Project

- **Play it (Windows and macOS builds, with run steps and SHA-256 hashes):** https://github.com/SadManQT/nasa-space-apps-2026/releases
  - **[status on 12 Nov]** The newest published build is the preview `v0.1.0-preview.20261105`; every push since is exported and smoke-tested for Windows by GitHub Actions. Put the judging release tag link here when it is published (board M3-93).
- **Source code, documentation and the full design:** https://github.com/SadManQT/nasa-space-apps-2026
- **Five-minute judge route:** title screen → **New Expedition** → Chapter 1. Walk to the Mission Table and press **E**, plan a shift, press **Try it** to see the forecast, then **Lock in shift**. Open a **Data Card** to see the NASA source behind a number.

---

## 4. Project Details

### Why: the problem

Space-themed STEM content often oversimplifies the engineering trade-offs that define a real mission, or presents them at a level too complex to hold a young learner's attention. Our challenge, *Build a Junior Astronaut Mission Trainer*, asks for "an interactive game or app that lets students run a lunar or Martian outpost, balancing competing demands like life support, radiation shielding, power, and food production, so they experience firsthand the decisions that determine whether a mission fails or succeeds."

A trade-off is only felt when it costs you something you care about. So we gave the player one small, living thing to protect.

### What: the game

Four cadets (Kai on power and heat, Amara on air, Mei on the garden, Rafi on space weather) run Aurora Station on the Shackleton–de Gerlache ridge in April 2046. In Chapter 1 the Sun sets for 36 hours, the link to Earth is cut in a training exercise, and a replay of a real solar storm arrives. The crew must stay safe, the base must keep running, and Alo, a purple-stemmed *Brassica rapa* mustard plant, must survive to bloom.

**The four demands, always on screen.** Outpost Status cards show power, life support, shielding and food at all times, with a forecast before any choice is locked in. The numbers below are Chapter 1's main puzzle, P-02 (game-design/08_PUZZLE_DESIGNS.md).

| Demand | What the player manages | Where the number comes from |
|---|---|---|
| Life support | An air tank that holds 10 units. Four crew breathe 1 unit per 7.2-hour shift; the air maker turns 1 energy into 1 air, up to 2 per shift. If air reaches 0, flight rules stop the mission. | NASA BVAD Rev 2: 0.895 kg of oxygen per person per day, so 1 air unit = 4 × 0.895 × 7.2 / 24 = 1.07 kg |
| Radiation shielding | A water wall of up to 6 units plus 2 crate units, S = min(6, W + K). The storm dose must stay at 3 training units or less. At the alarm the player chooses PUMP, STACK or WAIT. | 6 units = 20 g/cm² of water (NASA LaRC: Townsend et al. 1988; Clowdsley 2021); storm timing from NASA DONKI and GOES-13 |
| Power | A battery of 20 sun-drops (1 drop ≈ 10 kWh). Daylight adds 8 per shift in shifts 1–2; the five dark shifts add nothing. Heat, the air maker and the grow lamp all spend drops. A demand below zero is a blackout. | NASA LaRC 10 kW relocatable south-pole solar array: 8 drops × 10 kWh / 7.2 h = 11.1 kW, 56 % of two arrays |
| Food production | Garden condition, Alo's health and 12 crew-days of rations (four crew eat 1.2 per shift). Light and warmth cost power; water is shared with the shield. | NASA BVAD food rate; NASA OSDR *Brassica rapa* grown on the ISS; seed-to-seed *Brassica rapa* on Mir |

**Real decisions, real consequences.** Nothing is pre-filled: the player sets heat, air production, garden light and water for every shift, presses **Try it** to see the real forecast, then locks the shift in. Each cadet's role card holds facts the others need. The night ends in one of four endings: Golden Bloom (an expert goal), Bloom, Alo Lost (retry only) or Mission Stopped. Bloom continues the story; the others teach through a retry from the right checkpoint. A shift-by-shift replay of the player's decisions (what they chose, what the forecast said, what happened, and why) is followed by a predict–observe–explain science debrief (board M1-19, done).

**A story that makes the science matter.** A first-bloom mystery runs through eight chapters and one Moon year: pollination by hand, a moonquake leak, a rover trip into a cold trap, meteor impact flashes, a total lunar eclipse on 12 January 2047, a "what if" super-storm and a relay up Mons Malapert to bring back the link to Earth. Every chapter adds a new trade-off with its own NASA data.

**Built with care for young players.** Captions are on and nothing is timed by default; text can be 1.5 times larger and motion can be reduced. Every spoken line has a caption. The game runs offline, so a classroom needs no internet.

**What is in the repository today [status on 12 Nov]:**
- A Godot 4.7 3D game that starts at the title screen and plays all 8 chapters, 32 missions and 96 scenes, with voiced and captioned dialogue, saves, retries and a decision replay and debrief.
- All 16 puzzles as interactive panels: plan, press **Try it** to see the forecast from the same simulation, then lock in. Mission rules, risk cards and hints sit one click away.
- A clear path through every scene: a goal card with the distance to the ◇ marker, a "Next" line after each job, a What now panel on **H**, and a short how-to clip the first time a mechanic appears.
- Data Cards for all 16 puzzles and 19 narrated science explainer clips, every number drawn from the NASA fixtures.
- The exteriors stand on real south-pole terrain built from LRO LOLA elevation data, lit by JPL Horizons Sun positions for each scene's date.
- 386 voice lines, a 12-cue score, 38 sound effects and 18 cutscenes, all installed.
- 138 automated test suites (`game/tools/run_tests.sh`), including a walk through all 96 scenes and 13,048 checks on every line of player text at normal and 150 % text size. Rendering holds 60 fps on an Apple M4 Mac ([perf report](https://github.com/SadManQT/nasa-space-apps-2026/blob/main/production/qa/perf_2026-11-04.md)); each push is exported and smoke-tested on Windows.
- Four-player Class mode on one machine: choose Class (2–4 players) on New Expedition. Each cadet's crew note is read privately behind a pass-the-screen cover (or from printed cards), and all four roles sign every puzzle's exact choice and forecast before it locks in.
- Play-tested with 18 learners under 15. They told us the instructions were too hard, so every on-screen instruction was rewritten in words a nine-year-old can read, and the first puzzles now give step-by-step help.

### How: NASA data at the core

We designed from the data outward. For every puzzle we asked which NASA observation decides the number, then built the mechanic around it ([SCIENCE_AND_DATA.md](https://github.com/SadManQT/nasa-space-apps-2026/blob/main/docs/SCIENCE_AND_DATA.md) §B traces all 16 puzzles to their datasets).

1. **Fetch.** A plain Python script ([production/tools/fetch_nasa_data.py](https://github.com/SadManQT/nasa-space-apps-2026/blob/main/production/tools/fetch_nasa_data.py)) downloads the original records (DONKI, GOES-13, STEREO-A, CRaTER, JPL Horizons, the eclipse catalog, the Apollo catalog) or records values quoted from the cited papers with page references. No AI model produces a data value.
2. **Keep the provenance.** Each source becomes a small JSON fixture in `game/resources/data/nasa/` with its URL, ID or DOI, retrieval date, licence, the values used and every derived number with its formula and the puzzle it drives.
3. **Compute.** Derived numbers are computed, not typed: the 70-minute storm warning (particle onset minus flare start), the 1.07 kg air unit, the 36-hour night, Earth's height above the pole's horizon in April 2046, the 121.9 km to Mons Malapert. The terrain script ([production/tools/make_terrain.py](https://github.com/SadManQT/nasa-space-apps-2026/blob/main/production/tools/make_terrain.py)) reads LOLA elevation models, computes horizon masks and asks JPL Horizons where the Sun and Earth stand at each scene's date.
4. **Show it.** Data Cards read the same fixtures, so the player sees the dataset name, what was measured, what the game computed, the URL and the citation. Every display carries a label: **Observed**, **Computed** or a **training assumption**.
5. **Be honest about the gaps.** Numbers no dataset supports are tagged as gameplay values and listed publicly with the smallest change that would make each traceable (SCIENCE_AND_DATA.md §B3). Aurora Station, the cadets and the 2046 dates are fiction; the 2017 storm is a replay of real timing; the 2012 Moon strike in Chapter 7 is a labelled "what if".

The datasets, what each is, where it comes from and how the game uses it, are in the **NASA data sources used** field below. In short:
- **Storm and radiation:** NASA DONKI (September 2017 and July 2012), NOAA GOES-13 proton flux, NASA STEREO-A HET proton flux, LRO CRaTER dose at the Moon, NASA LaRC shielding studies, Chang'e-4 surface dose.
- **Light, sky and terrain:** LRO LOLA elevation models and the LOLA illumination study, JPL Horizons (three extracts), the NASA lunar eclipse catalog, the USGS/IAU gazetteer, the JPL polar communications study, ESA Moonlight.
- **Life support, power and food:** NASA BVAD, the NASA 10 kW relocatable solar array, NASA OSDR *Brassica rapa* on the ISS, *Brassica rapa* seed-to-seed on Mir, Wisconsin Fast Plants, Chang'e-4 cotton.
- **The Moon's surface:** Apollo shallow moonquakes (PDS), NASA Lunar Impact Monitoring, LCROSS, LRO Diviner, Chandrayaan-1 M3, Kaguya, NASA VIPER.

### Community involvement and benefits

- **Who it is for.** Learners aged 10 to 15 in classrooms and at home. The main night of Chapter 1 is designed to take about 20 minutes, so one night fits in a lesson.
- **Built for classrooms with little bandwidth.** It runs offline on Windows and macOS, needs no account, and is free under the Apache-2.0 licence, so schools can copy, translate and adapt it.
- **Teamwork by design.** Each cadet holds facts the others need, so the plan only works when the crew talks. In the four-player Class mode we registered, up to four learners share one machine: each reads their own role's facts privately, and every decision locks in only when all four roles sign it. The solo game gives one player all four roles.
- **From Bangladesh to the Moon.** Alo is *Brassica rapa*, the species of Bangladesh's own mustard and of the Wisconsin Fast Plants grown in classrooms around the world; the game opens on an Earth mustard field. The Academy's founder in the story, Dr Noor Rahman, is a Bangladeshi botanist. Players see their own world in the mission.
- **Honest science.** Every number shows its source and its label, so learners practise asking "how do we know?", the habit real mission teams depend on.
- **Learning evidence.** [metric from M1-22 when the playtest runs] The playtest measures time to the first objective, P-02 attempts, the ending reached, and whether each player can explain the numbers afterwards in one predict and one explain question.

Work on this project started before the hackathon with the permission of our Dhaka Local Lead; the full git history is public.

### Tools and technologies

**Our own work.** The story, the characters and every line of dialogue; all puzzle rules and numbers; the science mapping from NASA data to every mechanic; the art direction and every approval and rejection; and the review of every result. AI tools turned our written designs and approved images into assets and wrote code against our specifications; they were never allowed to change the story text or the puzzle numbers.

**Engine and code.** Godot 4.7 (MIT) and GDScript; Python 3 with NumPy for the data and terrain pipeline; Blender for procedural props, clean-up and previews; ffmpeg for audio and video; Chrome with playwright-core for the science explainer clips, which are drawn by code from the fixture numbers; GitHub Actions for the release builds.

**AI tools, credited (details in the Use of AI field).** Claude Code by Anthropic; OpenAI Codex; Google Antigravity (Gemini); Google Nano Banana Pro (Gemini 3 Pro Image); OpenAI GPT Image 2.5; Topaz Image Upscale; Tripo AI; Meshy; ElevenLabs; ByteDance Seedance 2.5; Google Veo 3.1 in Google Flow.

**Data.** NASA, with partner data from NOAA, USGS/IAU, ESA, ISRO, JAXA, CNSA and the Wisconsin Fast Plants Program, each labelled with its agency.

Full credits, licences and a credit row for every file in `game/assets`: [CREDITS.md](https://github.com/SadManQT/nasa-space-apps-2026/blob/main/CREDITS.md).

---

## 5. GitHub access

The repository is public and needs no login or permission request: https://github.com/SadManQT/nasa-space-apps-2026

- Licence: Apache-2.0 ([LICENSE](https://github.com/SadManQT/nasa-space-apps-2026/blob/main/LICENSE)).
- Start here: the [README](https://github.com/SadManQT/nasa-space-apps-2026#readme) (play, build and test steps), [docs/SCIENCE_AND_DATA.md](https://github.com/SadManQT/nasa-space-apps-2026/blob/main/docs/SCIENCE_AND_DATA.md) (every dataset and every puzzle number traced), [docs/AI_USE.md](https://github.com/SadManQT/nasa-space-apps-2026/blob/main/docs/AI_USE.md) and [production/AI_PROMPT_LOG.md](https://github.com/SadManQT/nasa-space-apps-2026/blob/main/production/AI_PROMPT_LOG.md) (every AI generation with its prompt), [docs/TEAM.md](https://github.com/SadManQT/nasa-space-apps-2026/blob/main/docs/TEAM.md) (team and roles).
- The team's task board, with every task, owner and piece of evidence: [production/plan/BOARD.html](https://github.com/SadManQT/nasa-space-apps-2026/blob/main/production/plan/BOARD.html).
- Large assets are stored with Git LFS: run `git lfs install` before cloning.
- Team page: https://www.spaceappschallenge.org/2026/find-a-team/the-last-braincell

---

## 6. Use of AI

We are a team of six building a full 3D Moon-outpost game, so we used AI where it saves the most time and where we have no specialist, and we disclose all of it. Every generation is logged with its tool, model, exact prompt (or where the prompt is stored), inputs, result and what a person changed or decided, including rejected results: [production/AI_PROMPT_LOG.md](https://github.com/SadManQT/nasa-space-apps-2026/blob/main/production/AI_PROMPT_LOG.md). The full disclosure is [docs/AI_USE.md](https://github.com/SadManQT/nasa-space-apps-2026/blob/main/docs/AI_USE.md).

**What AI made.** The 3D models of the characters, plants and props; concept art and character turnaround sheets; character animation clips; all 386 voice lines, the narration of the 19 science explainers, the 12-cue music score and the sound effects; the animated shots in the 18 cutscenes; and most of the game code, pipeline scripts and production documents, written against our specifications and checked by tests and a second AI.

**What the team made.** The story, characters and every line of dialogue (each voice line is our script word for word); every puzzle rule and number; the science mapping; the art direction; every approval and rejection; and the final review of every commit, each made from a team member's own GitHub account.

**No NASA dataset was given to a generative model.** The data extracts come from a plain Python script and from values quoted from cited papers.

| Tool (maker) | Why we used it | What it did | Representative prompt or input |
|---|---|---|---|
| Claude Code (Anthropic; Claude Opus 5.5) | One agent that plans, writes code and runs the asset pipeline end to end | Pipeline scripts, the NASA data fixtures and Data Cards, the LOLA terrain pipeline, game code (cutscene playback, audio runtime, rooms), the science explainer clips drawn by code, prompts for the other tools, cutscene assembly, documents (including this page), the team board | Board tasks, e.g. "Do board task M1-46 — exactly this one task — at senior, AAA production quality." |
| OpenAI Codex (GPT-6, GPT-6.1) | A second, independent model, so no AI's code goes unchecked | Game code and tests (Data Card runtime, Outpost Status, saves, the Mission Table panel and debrief), code review, bug hunts, release builds, the lunar rock kit (Blender scripts) | "Review these Godot 4.7 GDScript and shader changes … for real bugs only." |
| Google Antigravity (Gemini 4 Argon) | Research-heavy design documents | The requirements alignment and the real NASA mission practice behind every decision (trade studies, flight rules, Go/No-Go) | Board tasks M1-27 and M1-39 |
| Google Nano Banana Pro (Gemini 3 Pro Image), in ElevenLabs Flows and through Tripo | Concept art and consistent four-view sheets the 3D tools need | Style frames, character turnarounds, plant and prop concepts, screen portraits, cutscene start frames, free upscales of approved views | "Edit this image. Keep the same composition... Remove the eyes completely from the plant... no eyes, no face, no mouth." |
| OpenAI GPT Image 2.5 Sunburst | Frame edits | Some cutscene start and end frames, patch and hair fixes | Our approved frames plus a short edit prompt |
| Topaz Image Upscale v2 | Detail for 3D generation | 4× upscales of chosen turnaround views | No prompt |
| Tripo AI | A textured 3D model from an approved image in minutes | The five characters and their EVA suits, plants and props, Mixamo-standard skeletons | No text prompt: image-to-3D from our approved sheets |
| Meshy | Motion for the characters | Animation clips and five story motions (pollinate, water, inspect, type, repair) | "A person stands at a waist-high plant tray, leans in slightly and gently dabs the centre of a small flower with a fine brush …" |
| ElevenLabs (eleven_v4, eleven_music_v2_5, Sound Effects v2) | Adult character voices, an original score and effects without a studio | All 383 voice lines from our script, the 12-cue score, the sound effects | The script line with a delivery tag, e.g. "[warm, gentle, a recorded message from long ago]" |
| ByteDance Seedance 2.5, in ElevenLabs Flows | Short animated shots from our start frames | The animated shots cut into cutscenes CS-01 to CS-17 | "Slow, steady cinematic push-in across the grey lunar ground toward the small base …" (motion only; no dialogue) |
| Google Veo 3.1, in Google Flow | One painterly Earth shot | The 6-second mustard-field shot that opens the game (CS-01) | "Gentle winter-morning breeze moving through the flowering yellow mustard field …" from our approved start frame |

**Checks on AI output.** Every 2D design sheet is approved by a person before 3D credits are spent. Every generated asset passes an automated asset gate and a visual review against our science rules (black sky, hard shadows, lunar gravity, plants never with faces, no NASA logos). Cutscene shots are checked frame by frame; voices are picked by matching a local Whisper transcript to the script. AI-written code is reviewed by a second AI and by 136 automated test suites.

---

## 7. NASA data sources used

All extracts ship offline in `game/resources/data/nasa/`, one JSON file per source with its URL, ID or DOI, retrieval date, licence, values and formulas. The full table, with every ID and every puzzle it drives, is [docs/SCIENCE_AND_DATA.md](https://github.com/SadManQT/nasa-space-apps-2026/blob/main/docs/SCIENCE_AND_DATA.md) §B. Data Cards in the game read the same files.

### NASA data (21 sources)

**Storm and radiation**
1. **NASA DONKI, 4–12 September 2017** (NASA GSFC Community Coordinated Modeling Center): the space-weather database of flares, CMEs and particle events. <https://ccmc.gsfc.nasa.gov/tools/DONKI/> · The game uses the real timeline: the X8.2 flare began at 15:35 UT on 10 September 2017 (peak 16:06 UT, active region 12673); particles above 100 MeV arrived at 16:25 UT and above 10 MeV at 16:45 UT. That gives the player's **70-minute warning** before the storm reaches the shelter (P-02 shift 5) and Rafi's shift-2 forecast from the X9.3 flare of 6 September.
2. **NASA DONKI, 22–26 July 2012**: the CME of 23 July 2012 at 3,435 km/s, aimed at STEREO-A, not Earth; particle onset 03:59 UT. <https://ccmc.gsfc.nasa.gov/tools/DONKI/> · Drives the Chapter 7 storm, shown on screen as a "what if" it had hit the Moon (P-13, P-14).
3. **STEREO-A HET proton flux** (NASA SPDF CDAWeb, `STA_L1_HET`): one-minute proton flux measured by the STEREO-A spacecraft. <https://cdaweb.gsfc.nasa.gov/hapi> · The fluence in six 7.2-hour steps from onset (80 MeV: 0.16, 0.69, 1.00, 0.02, 0.01, 0.00 of the peak step) is shown beside the game's storm waves in Chapter 7.
4. **LRO CRaTER daily dose** (NASA LRO; CRaTER team, University of New Hampshire; archived at NASA PDS PPI): radiation dose measured in lunar orbit. <https://crater-products.sr.unh.edu/data/inst/dose/table_l30drate.php> · The D1 detector rose from 0.57 to 3.92 mGy per day (×6.8) between 22 and 24 July 2012: what really reached the Moon. Shown on the Chapter 7 Data Card.
5. **Protecting astronauts from space radiation on the lunar surface** (NASA LaRC, Clowdsley 2021, NTRS 20210009760). <https://ntrs.nasa.gov/citations/20210009760> · 20 g/cm² of hydrogen-rich shielding is NASA's target; a full water wall of 6 units = 20 g/cm², so 1 unit = 3.3 cm of water. Its modelled August 1972 storm dose (185 mSv behind 5 g/cm² down to 85 mSv behind 15 g/cm²) appears on the shielding card and explainer. The storm-shelter anchor for the same 20 g/cm² of water is Townsend, Nealy and Wilson 1988 (NASA TM-100620, <https://ntrs.nasa.gov/citations/19880016043>).

**Light, sky and terrain**

6. **LRO LOLA elevation models of the south pole** (NASA GSFC Planetary Geodynamics Data Archive, products 90 and 78; data DOI 10.60903/gsfcpgda-lola-spole; cross-checked with NASA PDS LDEM_80S_20M). <https://pgda.gsfc.nasa.gov/products/90> · The game's exteriors are built from this terrain. Aurora stands at 89.44° S on the Shackleton–de Gerlache connecting ridge, 1,959.5 m above the reference sphere; the Mons Malapert summit is at 4,993.6 m; a computed road to the cold trap is 8.6 km with no slope above 11.88°, under the 15° rover limit.
7. **Illumination of the lunar poles from LOLA** (NASA GSFC, Mazarico et al. 2011, NTRS 20120010094). <https://ntrs.nasa.gov/citations/20120010094> · A Shackleton-rim site's longest total darkness is about 1.5 days, so the game's night is 5 dark shifts × 7.2 h = 36 hours, labelled a training scenario sized to the study.
8. **JPL Horizons: the Sun from the south pole, 2046–2047** (NASA JPL, DE441). <https://ssd.jpl.nasa.gov/horizons/> · The Sun's height swings between −1.56° and +1.59°, which is why it stays low on the horizon all year; midwinter falls on 1 May 2046.
9. **JPL Horizons: Earth and Sun from the pole, April 2046.** <https://ssd.jpl.nasa.gov/horizons/> · Earth set at the pole on 15 April 2046 and rose on 28 April; through Chapter 1's night it stayed 3.4° to 1.4° below the horizon. The game says plainly that its shift-4 Earth-link cutoff is an authored training event, not an Earth-set.
10. **JPL Horizons: Earth from Mons Malapert, April 2047.** <https://ssd.jpl.nasa.gov/horizons/> · Earth stands at azimuth 357.9°–358.0° and elevation −2.3° (geometric), so the summit relay must be high enough to see over the horizon. Drives the dish-aiming puzzle P-16.
11. **Lunar eclipse catalog 2001–2100** (NASA GSFC, Espenak; catalog no. 09755). <https://eclipse.gsfc.nasa.gov/LEcat5/LE2001-2100.html> · The total lunar eclipse of 12 January 2047: totality 70.0 minutes, partial phase 208.9 minutes. Drives Chapter 6's eclipse power plan (P-11, P-12).
12. **Lunar pole illumination and communications maps** (NASA JPL Interplanetary Network Progress Report 42-176, Bryant 2009). <https://ipnpr.jpl.nasa.gov/progress_report/42-176/176C.pdf> · The best south-pole site has 92 % solar availability and 51 % direct view of Earth; some peaks see Earth continuously. Explains why Aurora needs the Malapert relay.

**Life support, power and food**

13. **NASA Life Support Baseline Values and Assumptions Document (BVAD) Rev 2, 2022** (NASA JSC, NASA/TP-2015-218570/REV2). <https://ntrs.nasa.gov/citations/20210024855> · Per crew member per day: 0.895 kg oxygen, 1.085 kg CO₂, 0.800 kg food, 3.217 kg water. One air unit = 4 × 0.895 × 7.2 / 24 = 1.07 kg of oxygen, so four crew breathe 1 unit per shift and five breathe 1.25; four crew eat 1.2 crew-days of food per shift. Used in every chapter.
14. **Relocatable 10 kW solar array for lunar south pole missions** (NASA LaRC, Vertical Solar Array Technology, NASA/TM-20210011743). <https://ntrs.nasa.gov/citations/20210011743> · 10 kW per array, blanket raised 10 m on a 16 m mast. The game's daylight income of 8 sun-drops per shift is 11.1 kW, 56 % of two such arrays, labelled an engineering estimate.
15. **NASA OSDR: *Brassica rapa* grown on the ISS** (NASA Open Science Data Repository / GeneLab; OSD-59 with Roscosmos, OSD-412 Veggie). <https://osdr.nasa.gov/bio/repo/data/studies/OSD-59> · Mizuna (*Brassica rapa*) grew for 27 days in the Lada chamber; the Veggie protocol used 200–300 µmol m⁻² s⁻¹ of light. Grounds the garden lamp's OFF / DIM / FULL settings and one plant per cassette.
16. ***Brassica rapa* seed-to-seed on Mir** (NASA-funded, Musgrave et al. 2000, NTRS 20040141614). <https://ntrs.nasa.gov/citations/20040141614> · Full life cycles, hand-pollinated, in a 122-day run in the Svet greenhouse. Grounds Chapter 2's hand pollination and the seed harvest.

**The Moon's surface**

17. **Apollo shallow moonquakes** (NASA PDS Geosciences Node, Nakamura 1979 catalog). <https://pds-geosciences.wustl.edu/lunar/urn-nasa-pds-apollo_seismic_event_catalog/data/nakamura_1979_sm_locations.csv> · 28 shallow quakes in 1971–1976; the south-polar one on 13 March 1973 at 84° S, magnitude 3.2. Drives the Chapter 3 moonquake and leak hunt (P-05).
18. **NASA Lunar Impact Monitoring** (NASA MSFC Meteoroid Environment Office). <https://www.nasa.gov/meteoroid-environment-office/lunar-impact-monitoring/> · Two telescopes must both see a flash before it counts; 126 calibrated flashes in five years, 62 % linked to meteor showers. Drives Chapter 5's flash review (P-10).
19. **LCROSS water in Cabeus** (NASA ARC, Colaprete et al. 2010, DOI 10.1126/science.1186986). <https://science.nasa.gov/mission/lcross/> · 5.6 ± 2.9 % water ice by mass. The reference for Chapter 4's ice samples (P-07).
20. **LRO Diviner cold traps** (NASA LRO, Paige et al. 2010, DOI 10.1126/science.1187726). <https://www.diviner.ucla.edu/science> · 38 K (−235 °C) below the surface at the LCROSS site. Explains the cold trap and why the seed vault stays frozen (P-07, P-08).
21. **NASA VIPER rover.** <https://science.nasa.gov/mission/viper/rover-and-instruments> · Designed for slopes up to 15°: the rover's limit in Chapters 4 and 8 (P-07, P-15).

### Partner and other data (8 sources, labelled with their agency)

22. **GOES-13 EPEAD proton flux** (NOAA NCEI). <https://www.ncei.noaa.gov/products/goes-1-15/space-weather-instruments> · The 10 September 2017 storm at Earth orbit: >10 MeV flux passed 10 pfu at 16:45 UT and peaked at 1,493.5 pfu on 11 September at 11:45 UT. Drawn as the storm chart on the Chapter 1 Data Card and debrief.
23. **Gazetteer of Planetary Nomenclature** (USGS Astrogeology / IAU). <https://planetarynames.wr.usgs.gov/Feature/16338> · From the pole to Mons Malapert is 121.9 km on a 1,737.4 km sphere: the game's "120 km each way" (P-15) and the dish bearing (P-16).
24. **Moon Mineralogy Mapper on Chandrayaan-1** (ISRO mission with a NASA instrument, Li et al. 2018, DOI 10.1073/pnas.1802345115). <https://doi.org/10.1073/pnas.1802345115> · Exposed ice shows in only about 3.5 % of cold traps, so the player learns to survey, not assume (P-07).
25. **SELENE (Kaguya) Terrain Camera** (JAXA, Haruyama et al. 2008). <https://darts.isas.jaxa.jp/planet/pdap/selene/> · Shackleton's floor is below about 90 K but shows no exposed pure ice at 10 m resolution (P-07, P-08).
26. **Wisconsin Fast Plants** (University of Wisconsin–Madison). <https://fastplants.org/frequently-asked-questions/> · *Brassica rapa* flowers in about 14 days, needs pollen from another plant, and sets seed about 40 days after planting. Sets Alo's and Tara's calendar (P-03, P-06).
27. **Chang'e-4 Lunar Lander Neutrons and Dosimetry** (CNSA mission, Kiel University instrument, Zhang et al. 2020, DOI 10.1126/sciadv.aaz1334). <https://doi.org/10.1126/sciadv.aaz1334> · The first dose measured on the Moon's surface: 13.2 ± 1 µGy/h. Anchors the route-dosimeter scale (P-14).
28. **Chang'e-4 cotton experiment** (CNSA mission, Chongqing University, Qiu et al. 2021, DOI 10.3390/ijms222111723). <https://doi.org/10.3390/ijms222111723> · A cotton seed germinated on the Moon in 2019 and did not survive the lunar night: the real trial behind the story's opening (P-09).
29. **Moonlight lunar communications** (ESA). <https://www.esa.int/Applications/Connectivity_and_Secure_Communications/Moonlight2> · Terrain and the Moon's curve can block the line of sight to Earth at the south pole; relays fix it (P-15, P-16).

**Registered sources [status on 12 Nov].** Our registration named six sources: LRO LROC polar illumination maps, LRO LOLA terrain, JPL Horizons, NASA DONKI, LRO CRaTER and NASA BVAD. Five are in the game as listed above. The LROC illumination map is not processed yet; the illumination the game uses today comes from the LOLA study (source 7) and the LOLA-plus-Horizons horizon computation (source 6). The 2017 CRaTER storm curve is also still to process; until then the 2017 card shows GOES-13 at Earth orbit, labelled as such.

---

## 8. References

**Data and studies** (each with its link in the field above; IDs and DOIs in docs/SCIENCE_AND_DATA.md §B1)
- NASA GSFC CCMC, DONKI: https://ccmc.gsfc.nasa.gov/tools/DONKI/
- NOAA NCEI, GOES-13 EPEAD corrected proton flux, September 2017: https://www.ncei.noaa.gov/products/goes-1-15/space-weather-instruments
- NASA SPDF CDAWeb, STEREO-A HET (`STA_L1_HET`): https://cdaweb.gsfc.nasa.gov/hapi
- LRO CRaTER Legacy Data Products, daily average dose rates (Schwadron et al.), July 2012 (UNH; NASA PDS PPI): https://crater-products.sr.unh.edu/data/inst/dose/table_l30drate.php
- Barker, M. K. et al. (2021). Improved LOLA elevation maps for south pole landing sites. *Planetary and Space Science* 203, 105119. https://doi.org/10.1016/j.pss.2020.105119
- Barker, M. K. et al. (2023). A New View of the Lunar South Pole from LOLA. *The Planetary Science Journal* 4, 183. https://doi.org/10.3847/PSJ/acf3e1
- Smith, D. E. et al. (2010). The Lunar Orbiter Laser Altimeter investigation on the Lunar Reconnaissance Orbiter mission. *Space Science Reviews* 150, 209–241.
- Mazarico, E. et al. (2011). Illumination conditions of the lunar polar regions using LOLA topography. *Icarus* 211, 1066–1081. https://doi.org/10.1016/j.icarus.2010.10.030
- NASA JPL, Horizons On-Line Ephemeris System (DE441): https://ssd.jpl.nasa.gov/horizons/
- Espenak, F. & Meeus, J., Five Millennium Catalog of Lunar Eclipses, NASA GSFC: https://eclipse.gsfc.nasa.gov/LEcat5/LE2001-2100.html
- Bryant, S. (2009). Lunar Pole Illumination and Communications Maps Computed from Goldstone Solar System Radar Elevation Data. JPL IPN Progress Report 42-176. https://ipnpr.jpl.nasa.gov/progress_report/42-176/176C.pdf
- Ewert, M. K., Chen, T. T., Powell, C. D. (2022). Life Support Baseline Values and Assumptions Document, Rev 2. NASA/TP-2015-218570/REV2. https://ntrs.nasa.gov/citations/20210024855
- Pappa, R. et al. (2021). Relocatable 10 kW Solar Array for Lunar South Pole Missions. NASA/TM-20210011743. https://ntrs.nasa.gov/citations/20210011743
- Clowdsley, M. (2021). Protecting Astronauts from Space Radiation on the Lunar Surface. Lunar Surface Innovation Consortium, 9 Feb 2021. https://ntrs.nasa.gov/citations/20210009760
- Townsend, L. W., Nealy, J. E., Wilson, J. W. (1988). NASA TM-100620. https://ntrs.nasa.gov/citations/19880016043
- NASA-STD-3001 Vol. 1 Rev B (2022), Crew Health. https://www.nasa.gov/wp-content/uploads/2020/10/2022-01-05_nasa-std-3001_vol.1_rev._b_final_draft_with_signature_010522.pdf
- Sugimoto et al. (OSD-59) and Hummerick et al. (OSD-412), NASA OSDR: https://osdr.nasa.gov/bio/repo/data/studies/OSD-59
- Musgrave, M. E. et al. Gravity independence of seed-to-seed cycling in *Brassica rapa*. NTRS 20040141614. https://ntrs.nasa.gov/citations/20040141614
- Nakamura, Y. et al. (1979). Shallow moonquake locations; NASA PDS Apollo seismic event catalog: https://pds-geosciences.wustl.edu/lunar/urn-nasa-pds-apollo_seismic_event_catalog/
- NASA MSFC Meteoroid Environment Office, Lunar Impact Monitoring: https://www.nasa.gov/meteoroid-environment-office/lunar-impact-monitoring/ ; Suggs, R. M. et al. (2014), NTRS 20150016513; Moser, D. E., Suggs, R. M., Ehlert, S. R. (2017), 2015 Geminid impact flashes, NTRS 20170004471
- Colaprete, A. et al. (2010). Detection of water in the LCROSS ejecta plume. *Science* 330, 463–468. https://doi.org/10.1126/science.1186986
- Paige, D. A. et al. (2010). Diviner Lunar Radiometer observations of cold traps in the Moon's south polar region. *Science* 330, 479–482. https://doi.org/10.1126/science.1187726
- Li, S. et al. (2018). Direct evidence of surface exposed water ice in the lunar polar regions. *PNAS* 115. https://doi.org/10.1073/pnas.1802345115
- Haruyama, J. et al. (2008). Lack of exposed ice inside lunar south pole Shackleton Crater. *Science* 322. https://doi.org/10.1126/science.1164020
- NASA VIPER rover and instruments: https://science.nasa.gov/mission/viper/rover-and-instruments
- USGS / IAU Gazetteer of Planetary Nomenclature: https://planetarynames.wr.usgs.gov/Feature/16338
- Zhang, S. et al. (2020). First measurements of the radiation dose on the lunar surface. *Science Advances* 6. https://doi.org/10.1126/sciadv.aaz1334
- Qiu, Jian, Zhang & Xie (2021). Plant gravitropism and signal conversion under a stress environment of altered gravity. *Int. J. Mol. Sci.* 22, 11723 (section 4.2). https://doi.org/10.3390/ijms222111723
- ESA, Moonlight: https://www.esa.int/Applications/Connectivity_and_Secure_Communications/Moonlight2
- Wisconsin Fast Plants Program, FAQ: https://fastplants.org/frequently-asked-questions/

**Software and services**
- Godot Engine 4.7 (MIT): https://godotengine.org
- Blender: https://www.blender.org · ffmpeg: https://ffmpeg.org · Python and NumPy: https://www.python.org, https://numpy.org · playwright-core: https://playwright.dev
- AI tools as listed in the Use of AI field; every generation in https://github.com/SadManQT/nasa-space-apps-2026/blob/main/production/AI_PROMPT_LOG.md

**Our documents**
- Science audit and data map: https://github.com/SadManQT/nasa-space-apps-2026/blob/main/docs/SCIENCE_AND_DATA.md
- Puzzle numbers: https://github.com/SadManQT/nasa-space-apps-2026/blob/main/game-design/08_PUZZLE_DESIGNS.md
- Credits and licences: https://github.com/SadManQT/nasa-space-apps-2026/blob/main/CREDITS.md

*An independent team project. It is not endorsed by NASA and uses no NASA logos.*
