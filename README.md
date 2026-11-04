# Last Light Academy

**Run a Moon base. Keep the crew safe. Help the first flower bloom on the Moon.**

NASA Space Apps Challenge 2026 · Challenge: **[Build a Junior Astronaut Mission Trainer](https://www.spaceappschallenge.org/2026/challenges/build-a-junior-astronaut-mission-trainer/)** · Team **The Last BrainCell** · Local event: Dhaka, Bangladesh

*An independent team project. It is not endorsed by NASA and uses no NASA logos.*

**Jump to:** [Pitch](#the-pitch) · [Videos](#videos) · [Play it](#play-it) · [Screenshots](#screenshots) · [The challenge](#how-it-answers-the-challenge) · [NASA data](#nasa-data) · [Status](#status-4-november-2026) · [Use of AI](#use-of-ai) · [Licence and credits](#licence-and-credits) · [Team](#team) · [Full design](#the-full-design)

---

## The pitch

Last Light Academy is a 3D story game for ages 10–15, for classrooms and families. Four young cadets run Aurora Station at the Moon's south pole. In Chapter 1 the Sun sets for 36 hours, Earth sinks below the horizon, and a replay of the real solar storm of 10 September 2017 arrives. The cadets must keep the crew safe, keep the base running and keep Alo, a small mustard plant, alive until sunrise. Power, air, shielding water and food all come from the same small supply, so every choice is a trade-off: the water that shields the crew is the water Alo drinks. The game's key numbers come from NASA data, and in-game Data Cards show each source and say what is measured, what is computed and what is a training assumption. The full story runs over 8 chapters, 32 missions and 96 scenes across one Moon year.

## Videos

| Video | Length | Link |
|---|---|---|
| Local judging video (with the working game) | 240 s | *Link added after upload, due 13 Nov 2026* |
| Global video | 30 s | *Link added after upload, due 14 Nov 2026* |
| Concept pitch video (made before the hackathon) | 3:59 | [LastLightAcademy_pitch_video.mp4](LastLightAcademy_pitch_video.mp4) (Git LFS: use **Download** on the file page) · [English subtitles (.srt)](LastLightAcademy_pitch_video.srt) |

## Play it

**Download.** Windows (x86_64) and macOS (universal) builds of version `0.1.0-preview.20261104` are built and pass a start-up test on fresh GitHub machines ([run 41712680810](https://github.com/SadManQT/nasa-space-apps-2026/actions/runs/41712680810)). They are not published yet: the team approves the release first. When they are, they will be on the [Releases page](https://github.com/SadManQT/nasa-space-apps-2026/releases).

- **Windows:** unzip, keep `LastLightAcademy.exe` and `LastLightAcademy.pck` together, run the EXE.
- **macOS:** unzip, move the app to Applications and open it. The build is not signed. If macOS blocks it, use **Privacy & Security → Open Anyway**.

There is no browser version. A test web build was about 310 MB and some symbols did not draw ([release notes](production/qa/release_2026-11-04.md)).

**Run from source** (Godot 4.7; tested with 4.7.2):

```bash
git lfs install
git clone https://github.com/SadManQT/nasa-space-apps-2026.git
```

Then open `game/project.godot` in the Godot editor and press **Play** (F5). The first time, Godot imports about 460 MB of assets, so it takes a while. From a terminal: `godot --headless --path game --import` once, then `godot --path game`.

**Controls:** WASD to move, hold the right mouse button to look, **E** to use what is in front of you, **Esc** to pause, Tab / arrow keys / Enter for on-screen buttons. Captions are on and nothing is timed by default. Settings can make text 1.5 times larger and reduce motion.

**Judge route (5 minutes):** title screen → **New Expedition** → Chapter 1. Walk to a console and press **E**, watch the four status cards change, and open a **Data Card** to see the NASA source behind a number.

**Tests and builds:** `game/tools/run_tests.sh` runs every test suite (set `GODOT=/path/to/godot` if needed). `python3 production/qa/build_release.py --platform windows --install-tools --smoke` (or `--platform macos`) makes a release build and checks it starts.

## Screenshots

From the current build (Godot 4.7, 1280×720). The rooms are still grey test rooms; the final room art is in progress.

| Title screen | The crew in the Commons | Power, air, shielding and food |
|---|---|---|
| ![Title screen: Run a real mission decision](production/qa/evidence/M1-20_native_title.png) | ![The crew around the Mission Table in the Commons](production/qa/evidence/M1-17_LOC-01.png) | ![Outpost Status cards for power, life support, shielding and food, with a forecast and Amara's caption](production/qa/evidence/M1-28_shift_forecast.png) |

## How it answers the challenge

The challenge asks for a game in which students *"run a lunar or Martian outpost, balancing competing demands like life support, radiation shielding, power, and food production"*. The first four demands are the four Outpost Status cards the player always sees; the fifth is the shift plan itself. Each rests on real data. Numbers below are from Chapter 1's main puzzle, P-02 ([game-design/08_PUZZLE_DESIGNS.md](game-design/08_PUZZLE_DESIGNS.md)). The simulation and the status cards already use them; the panels where the player sets each choice are in progress (see [Status](#status-4-november-2026)).

| Demand | What the player manages | Real data behind it |
|---|---|---|
| **Power** | Energy in "sun-drops" (1 drop ≈ 10 kWh). The battery holds 20. Daylight adds 8 per shift; the 36-hour night adds none. The heater, the air maker and the grow lamp all spend drops. | NASA 10 kW south-pole solar array study; LOLA illumination study of Shackleton's rim; JPL Horizons Sun positions |
| **Life support** | Air tank (holds 10 units; 1 unit = 1.07 kg of oxygen, what four people breathe in 7.2 hours). The crew uses 1 unit per shift. If the air runs out, flight rules stop the mission. | NASA Life Support Baseline Values and Assumptions Document (BVAD), 2022 |
| **Radiation shielding** | A water wall (6 units = 20 g/cm² of water) plus supply crates make the shelter. Crew storm dose must stay at 3 or less. When the alarm sounds: **PUMP**, **STACK** or **WAIT**. | NASA DONKI and GOES-13 records of the 10 Sep 2017 storm; NASA lunar shielding guidance (20 g/cm²) |
| **Food production** | Crops and rations (4 crew eat 1.2 crew-days of food per shift). The garden and Alo need light and warmth, which cost power, and water, which the shield also needs. | NASA BVAD food rates; NASA OSDR *Brassica rapa* growth on the ISS; *Brassica rapa* grown seed-to-seed on Mir |
| **Running the outpost** | Seven shifts of 7.2 hours on the Mission Table. Each cadet holds information the others need. Preview a plan, commit it, see what happens. After Earth sets, there is no help from Mission Control. | JPL Horizons: from the pole, Earth set on 15 Apr 2046 and stays below the horizon all of Chapter 1's night |

Chapters 2–8 add more of the same trade-offs: pollination and seed harvest, an air leak after a moonquake, a rover trip into a cold trap, an eclipse, a "what if" super-storm, and a relay to bring back the link to Earth ([docs/SCIENCE_AND_DATA.md](docs/SCIENCE_AND_DATA.md) §B2 traces every puzzle).

## NASA data

The game ships small offline extracts of 28 NASA and partner sources (`game/resources/data/nasa/`), so it needs no internet. Each extract keeps its source URL, ID or DOI, retrieval date, licence, the values used and the formulas. Data Cards in the game read these files. **The full table, with IDs, URLs and licences, is [docs/SCIENCE_AND_DATA.md](docs/SCIENCE_AND_DATA.md) §B.**

| NASA source | What the game takes from it | Where the player meets it | In the game |
|---|---|---|---|
| **DONKI** space-weather records, 6–10 Sep 2017 | The real storm timeline: X8.2 flare at 15:35 UT on 10 Sep, particles 70 minutes later | Chapter 1 storm alarm and Rafi's forecast | Yes |
| **LOLA** illumination study (Mazarico et al. 2011) | A Shackleton-rim site's longest darkness, about 1.5 days → the 36-hour night | Chapter 1 night length | Yes |
| **JPL Horizons** | The low polar Sun; when Earth sets and rises; where Earth is from Mons Malapert | Earth-set in Chapter 1; relay aiming in Chapter 8 | Yes |
| **BVAD** Rev 2 (2022) | Oxygen 0.895 kg and food 0.8 kg per person per day | Air and food in every chapter | Yes |
| **Relocatable 10 kW Solar Array** / VSAT (NASA LaRC) | The power scale: 1 sun-drop ≈ 10 kWh | Power card, solar masts | Yes |
| Lunar radiation shielding guidance (Clowdsley 2021, NASA LaRC) | 20 g/cm² of water makes a storm shelter | Water wall and shelter rating | Yes |
| **LRO CRaTER** dose at the Moon; **DONKI** and **STEREO-A** records, July 2012 | The real dose rise at the Moon and the three-wave particle profile | Chapter 7 "what if" storm, clearly labelled | Yes |
| **OSDR** *Brassica rapa* on the ISS (OSD-59, OSD-412); seed-to-seed on Mir | Grow-light levels; one plant per cassette; a full life cycle in space | The garden lamp and Alo | Yes |
| **LCROSS**, **Diviner**, **VIPER** | Ice at 5.6 % by mass, 38 K cold traps, a 15° rover slope limit | Chapter 4 rover trip | Yes |
| Lunar eclipse catalog (Espenak); Apollo moonquake catalog; Lunar Impact Monitoring | The 12 Jan 2047 eclipse; the real 1973 south-polar quake; how meteor flashes are checked | Chapters 3, 5 and 6 | Yes |
| **LROC** south-pole illumination map; **LOLA** elevation models | The real horizon and ground around Aurora | Terrain and the "Why here?" map | In progress |

Partner data, labelled with its agency: NOAA GOES-13, USGS/IAU place names, ESA Moonlight, ISRO Chandrayaan-1, JAXA Kaguya, CNSA Chang'e-4, and the Wisconsin Fast Plants Program.

**Honesty labels.** Aurora Station, the cadets, Alo and the 2046 dates are fiction. The 2017 storm is a historical replay; the 2012 storm hitting the Moon is a "what if". Numbers that no dataset supports are listed in [docs/SCIENCE_AND_DATA.md](docs/SCIENCE_AND_DATA.md) §B3.

## Status (4 November 2026)

The hackathon is on 13–14 November 2026. Work started earlier, with the Dhaka Local Lead's permission. This is what the repository holds today; live status is in [PRODUCTION_HANDBOOK.md](PRODUCTION_HANDBOOK.md) §10, and all open work is on the [team board](production/plan/BOARD.html).

**Built and tested**
- A Godot 4.7 3D game that starts at the title screen and runs a campaign through all 8 chapters and 96 scenes, with captions, saves and retries. Every automated test suite passed in the latest full run (`game/tools/run_tests.sh`).
- Six lit Chapter 1 rooms with the five 3D characters; the crew stand, talk and look at the speaker.
- Outpost Status cards for power, life support, shielding and food, with forecasts before a choice is committed.
- Data Cards for all 16 puzzles, from the 28 offline NASA and partner extracts.
- Audio made and installed: all 383 spoken voice lines, 12 music cues and 35 sound effects.
- Cutscenes CS-01 to CS-09 and CS-18 made and installed in the game folder.
- Speed: on an Apple M4 Mac (Metal, 1280×720), 95 % of frames take 9.7–11.3 ms in the Greenhouse and the five-character Commons, inside the 16.7 ms needed for 60 fps ([perf report](production/qa/perf_2026-11-04.md)). Other hardware is not measured yet.
- Windows and macOS release builds that start on clean machines (not yet published, see [Play it](#play-it)).

**In progress**
- Interactive P-01 and P-02 panels, so the player builds the night plan. Today the game applies the designed plan when the player commits.
- Playing the voices, music, effects and cutscenes inside the campaign. Today the cutscenes play in the developer showcase, and the campaign shows every line as a caption.
- Cutscenes CS-10 to CS-17.
- Four-player Class mode with private role clues, as registered.
- Chapter 1 endings, decision replay and the science debrief.
- Final room art and real south-pole terrain from LOLA data.
- Rooms and interactive puzzles for Chapters 2–8.
- The 240 s and 30 s videos, and a playtest with learners.

## Use of AI

We used AI tools, and we disclose all of them. Every generation is logged with its exact prompt, inputs, result and the team's changes in **[production/AI_PROMPT_LOG.md](production/AI_PROMPT_LOG.md)**. The full disclosure (why each tool, sample prompts, the data it worked on) is **[docs/AI_USE.md](docs/AI_USE.md)**.

| Tool | Maker | What it did |
|---|---|---|
| Claude Code (Claude Opus 5.5 where recorded) | Anthropic | Pipeline scripts, prompts for the other tools, documentation (including this README), NASA data extracts, code fixes, orchestration; the pitch video's scripts, music and edit |
| Codex (GPT-6, gpt-6-astra) | OpenAI | Game code and tests, code review, bug hunts, release builds, the lunar rock kit |
| Antigravity (Gemini 4 Argon) | Google | Requirements and NASA mission-practice documents; performance work; the interactive puzzle panels now in progress |
| Nano Banana Pro (Gemini 3 Pro Image) | Google | Concept art, character turnaround sheets, screen portraits, cutscene start frames |
| GPT Image 2.5 Sunburst | OpenAI | A few cutscene frame edits |
| Topaz Image Upscale v2 | Topaz Labs | 4× upscales of turnaround views |
| Tripo AI | VAST | 3D models of the characters, plants and props, and character skeletons |
| Meshy | Meshy | Motion-capture animation clips and five text-to-motion story actions |
| ElevenLabs (eleven_v4, eleven_music_v2_5, Sound Effects v2) | ElevenLabs | All 383 voice lines, 12 music cues and 35 sound effects; the Flows workspace that ran the image and video models |
| Seedance 2.5 | ByteDance | Short cutscene video shots from our start frames |

Google Veo was not used. The tool behind the 2–3 November campaign code is not recorded; the team is confirming it ([docs/AI_USE.md](docs/AI_USE.md)).

**What the team did itself:** the story, characters and every line of dialogue; all puzzle rules and numbers; the science mapping; the art direction and every approval and rejection; and the review of AI-written code, which is also checked by a second AI and the test suites. AI tools turned our written designs and approved images into assets, and wrote code against our specifications. The NASA data extracts come from a plain Python script ([production/tools/fetch_nasa_data.py](production/tools/fetch_nasa_data.py)) that downloads the original records, or records values quoted from the cited papers; no AI model produces the data values.

## Licence and credits

- **Licence:** our own code and content are released under the **[Apache License 2.0](LICENSE)**. Everything else keeps its own licence.
- **Credits:** [CREDITS.md](CREDITS.md) credits every source, including free ones and generated content: Godot Engine (MIT), Blender, FFmpeg, Python, the Open Sans font built into Godot (SIL OFL 1.1), every NASA and partner dataset, the research papers, and every AI tool, with a line for every file in `game/assets`.
- **Pitch video:** solar-flare footage from NASA Goddard / SDO; character animations from Adobe Mixamo; font Baloo Da 2 (SIL OFL 1.1); rendered in Blender.

## Team

Team **The Last BrainCell** · Dhaka, Bangladesh · [Space Apps team page](https://www.spaceappschallenge.org/2026/find-a-team/the-last-braincell)

| Name | Role | GitHub |
|---|---|---|
| Nafis Mohtasim Ramim | Team leader | |
| Khandaker Shadman Sakib Siddiquee | Team member | [SadManQT](https://github.com/SadManQT) |
| Md. Asif Iqbal | Team member | |
| Abu Sayem Mohammed Tanvir | Team member | [SayemTanvir](https://github.com/SayemTanvir) |
| Shahariar Rahman Shanto | Team member | |
| MD ATIK KHAN | Team member | [ProgrammerAtik](https://github.com/ProgrammerAtik) |

## What is in this repository

| Path | What it is |
|---|---|
| [`game/`](game/) | The Godot 4.7 project: scripts, scenes, assets, offline NASA data, tests |
| [`docs/`](docs/) | Science and data plan, AI use, team, competition rules, final story and gameplay design |
| [`full-game-story/`](full-game-story/) | The canon story: 96 scenes ([STORY_FULL.md](full-game-story/STORY_FULL.md)) |
| [`game-design/`](game-design/) | Puzzle rules and numbers, characters, world, UI, audio and science-accuracy designs |
| [`production/`](production/) | Asset pipeline, AI prompt log, art bible, QA evidence and release scripts, team board |
| [`PRODUCTION_HANDBOOK.md`](PRODUCTION_HANDBOOK.md) | Decisions, pipeline and current status |
| [`CREDITS.md`](CREDITS.md), [`LICENSE`](LICENSE) | Credits and licence |

---

# The full design

> This part describes the finished game we are building. Some of it is not built yet; what works today is in [Status](#status-4-november-2026). More design detail: [docs/GAMEPLAY_DESIGN_FINAL.md](docs/GAMEPLAY_DESIGN_FINAL.md), [docs/STORY_FINAL.md](docs/STORY_FINAL.md) and [docs/CAMPAIGN_SEASON1.md](docs/CAMPAIGN_SEASON1.md).

## The idea in 30 seconds

> In 2019, the first plant ever to sprout on the Moon froze on its very first night.
>
> NASA plans to grow plants on the Moon again, including *Brassica rapa*: field mustard, the same yellow flower that
> covers Bangladesh's fields every winter.
>
> Four young cadets. One mustard plant named Alo. One Moon-night training scenario shaped by documented lunar science:
> the Sun disappears for a day and a half, Earth sinks below the horizon, and a labelled storm replay is considered.
>
> Keep the crew safe. Keep the base running. And at sunrise, Alo blooms.

**Last Light Academy** is a cooperative Moon-base mission game for classrooms and families. Four cadets run one
station at the Moon's south pole, and each controls one system:

| Cadet | System |
|---|---|
| **Kai** | power and heat |
| **Amara** | air (oxygen) |
| **Mei** | the garden, food and Alo |
| **Rafi** | the Safe Room (radiation shelter) |

Sunlight becomes **sun-drops** the team counts and shares. Each cadet gets a **secret** the others need. The game labels
what is observed, computed, a training assumption or fiction (see [NASA data](#nasa-data)).

**Why it matters:**

- **Every role matters.** Nobody sees everything. The plan only works when the cadets share what they know.
- **Real constraints.** Energy, air, heat, light and shielding all draw on the same limited supply, as on a real base.
- **Consequences you can see.** A preview shows the effect of a plan before you commit. The debrief shows every
  decision, what it caused, and the science behind it.
- **For every classroom.** Free, offline-ready, English-only, captioned and timer-free by default, with a readable judge route.

## The real history behind it

Everything in the story starts from something true:

| Year | What happened |
|---|---|
| **2016** | On the International Space Station, zinnias were dying of mould. NASA let astronaut **Scott Kelly** care for them on his own judgement instead of waiting for instructions from Earth. They **bloomed**. |
| **2019** | A cotton seedling in China's **Chang'e-4** lander became the first plant ever to sprout on the Moon. It **did not survive its first lunar night**. |
| **Next** | NASA's **LEAF** experiment is a sealed plant-growth chamber for the lunar surface, planned for one of the first Artemis landings. One of its plants is ***Brassica rapa*** (field mustard): the classroom "Wisconsin Fast Plant", which goes from seed to flower in about 14 days, and the same species as Bangladesh's **Tori mustard**. |

One flower links NASA, classrooms around the world and the fields of Bangladesh. That flower is **Alo**, which
means *light* in Bangla.

## The story: Chapter 1, *Night One*

**1. Last Light.** Aurora Station sits on the rim of **Shackleton crater**, near the Moon's south pole. Rim sites like
this are among the best-lit places on the Moon, sunlit for most of the year. But tonight is its **longest night of the
year**. Four cadets of Last Light Academy are running the base alone for the first time. Outside, in a
small sealed chamber like NASA's LEAF, sits Alo. The Sun slides behind the far mountains, the solar masts go dark, and
for the next **36 hours** the base lives on whatever is in the battery.

**2. The Drill.** Commander Ferreira, at Mission Control on Earth, calls a storm drill: *"Practice building the
shelter."* Then Rafi gets a private message: *"Sunspot 2673 just fired a giant flare. Another big one may come."*

**3. Earth-Set.** From the south pole, Earth slowly sinks below the horizon. *"Earth-set in ten seconds,"* says
Ferreira. *"From here, you're on your own."* The radio hisses, then goes silent. **No Sun. No Earth.**

**4. The Storm.** Rafi's radiation counter starts ticking: the first particles of a giant solar storm, a replay of the
real storm of **10 September 2017**. The screen flips: **THIS IS NOT A DRILL.** There are 90 seconds to pump water
into the shelter walls or stack crates. The crew goes into the Safe Room first; that part is never a choice. The catch:
**the water that shields the crew is the water Alo drinks.** In this scenario the radiation is not what threatens Alo:
frost and thirst are.

**5. First Light.** After a day and a half, a sliver of Sun climbs over the crater rim. Light pours into Alo's
chamber… and a tiny yellow flower opens: **the first flower ever to bloom on the Moon.** Days later, Earth rises again
and Ferreira's voice crackles back: *"You didn't survive the Moon. You ran it."*

**The reveal, in the debrief: what was real, what was computed, what was invented.**

- **Observed:** the storm's timing comes from NASA's DONKI record of 10 September 2017, and LRO's CRaTER instrument
  measured that storm at the Moon. On Mars, the Curiosity rover measured the same storm. LROC's polar map measured
  how often each spot near the pole is sunlit.
- **Computed** (once the team's processing is checked): Aurora's horizon and the Sun and Earth paths, from LOLA
  terrain and JPL Horizons. Until then, the 36-hour night and the Earth-set are labelled *training scenario*.
- **Simulated / fiction:** Aurora Station, the cadets, Alo, sun-drops, the 2046 dates, and what the storm does to
  this base.

Every ending closes Chapter 1 on its own. After a bloom, N.'s old recording plays and Mei finds Tara's bud: *Alo needs
a friend*. If Alo is lost, the crew is safe, Tara is still growing, and a locked recording waits *for the first bloom*.

## Characters

| Who | Role | In one line |
|---|---|---|
| **Kai** | Power: sun-drops and heat | Hates switching things off; first to say "we need to save!" |
| **Amara** | Air: oxygen | Loves exact numbers; turns power into air |
| **Mei** | Garden: food and Alo | Talks to her plants. "The garden is not a side system." |
| **Rafi** | Safe Room: radiation shield | Checks twice and warns early; his warnings get the shelter ready in time |
| **Alo** ("light" in Bangla) | A faceless field-mustard plant | Leans, droops, recovers and blooms through biological stages |
| **Commander Ferreira** | Instructor at Mission Control (Earth) | Calm and strict; only speaks while Earth is in the sky |
| **Rao** | Flight controller (Earth) | Friendly; one hint per shift until Earth-set |
| **Tara** ("star" in Bangla) | Alo's partner flower, grown indoors | Without Tara, Alo can't make seeds |
| **Dr. Noor Rahman ("N.")** | Expedition Zero's gardener, from Bangladesh | Left the seeds. Her name means "light", just like Alo's |

The cadets are adult anime-style (cel-shaded) 3D characters. Indoors they wear a navy duty coverall; outside, a white EVA
suit with navy and orange. Every outfit has the Bangladesh flag on the left shoulder and the Aurora mission patch on the
right. Each has a role colour: orange for Kai, cyan for Amara, green for Mei, purple for Rafi.

## How it plays

Players walk a compact 3D station in third person: four rooms (Power, Air, Garden, Safe Room), a corridor with the
**Mission Table**, an airlock, and Alo's chamber outside. Instead of abstract buttons, they work real-looking consoles,
valves and equipment.

### The core loop

**Observe → inspect → share what you know → preview → act → run the shift → see the consequences → update the plan.**

### The rules in one minute

1. **Sunlight makes sun-drops.** In daylight, two tall solar masts fill the **battery jar**. It holds 20 drops; extra
   drops spill and fade away.
2. **Every room runs on drops:** Kai's heater, Amara's air maker and Mei's grow lamp. The base basics (CO₂ scrubbers,
   fans, radio) always take 1 drop.
3. **Rafi's pumps move water, not drops.** The shelter's water wall is filled from Alo's water tank. Pumps are slow:
   one step per shift.
4. **Run the shift.** About 7 hours pass in a few seconds as a time-lapse.
5. **At night, no drops fall.** The jar is all you have.

### One shift (2 to 3 minutes)

1. **Secret.** Sometimes one cadet gets a private message: "For Kai only."
2. **Talk and plan.** While Earth is up, Rao offers one hint. A **ghost preview** shows the result *before* you commit.
3. **Run.** A time-lapse plays: the Sun moves, frost or warm light spreads, bubbles rise, Alo reacts.
4. **Result.** Big icons show what changed, and why.

### The night: 7 shifts of about 7 hours

| Shift | Sky | What happens |
|:---:|---|---|
| 1 | Day | Meet the crew. Secrets for Kai and Amara. Sun-drops pour in |
| 2 | Day | The **storm drill** (practice). A secret for Rafi |
| 3 | **Last Light** | The Sun sets behind the mountains. A secret for Mei |
| 4 | **Earth-set** | The radio goes silent, and the hints stop |
| 5 | **The Storm** | THIS IS NOT A DRILL: **PUMP**, **STACK** or **WAIT** |
| 6 | Storm | Particles keep coming; the wall decides the dose |
| 7 | The last dark shift | Will the jar last? |
| End | **First Light** | The Sun returns, Alo blooms (or not), then the debrief |

### The four jobs and their secrets

| Cadet | Controls | Secret | The trade-off |
|---|---|---|---|
| **Kai** | Night heater: COZY (2 drops) · COOL (1) · COLD (0) | "Tonight is the longest night of the year: about 36 hours without the Sun. Heat eats drops every night shift." | Warmth empties the jar; cold hurts Alo |
| **Amara** | Air maker: 0, 1 or 2 drops → +0, +1 or +2 air | "The jar can't hold all of today's sunlight. Make air now, and the tank keeps it for the night." | Air made at night eats night drops |
| **Mei** | Grow lamp: OFF · DIM (1) · FULL (2) | "In our scenario, radiation isn't Alo's danger. Frost and thirst are. Don't keep the wall full for long: that's Alo's water." | Light costs drops; frost and thirst cost Alo |
| **Rafi** | Pumps: FILL (+2 water into the wall) · HOLD · DRAIN (−2) | "Sunspot 2673 just fired a giant flare. Another big one may come within about two days." | Fill too late and the crew is exposed; keep it full too long and Alo goes thirsty |

### The storm: three choices

| Choice | What you do | Effect | The catch |
|---|---|---|---|
| **PUMP!** | A 15-second valve task (in Class Mode, the whole class claps) | +2 water into the shelter wall | 4+ water in the wall leaves Alo thirsty |
| **STACK!** | A 30-second puzzle: fit supply bundles around the bunks, as NASA plans for Orion crews | +2 shielding from crates, no water used | Everyone is building: no air, no lamp, heat on COOL this shift |
| **WAIT** | A tense countdown | Everything keeps running | Only safe if the shelter was ready earlier |

The storm drill in shift 2 uses the same tasks, so nobody meets the controls for the first time when it's real.

### What the game teaches without saying it

| Hard idea | How the game shows it | The real fact |
|---|---|---|
| Energy budgets | Sun-drops you count and move | Solar power only while the Sun is up |
| Battery limits | The jar holds 20; extra drops spill | Turn spare sunlight into air and growth |
| The polar Sun | The Sun circles the horizon behind mountains | Rim sites are sunlit most of the year; published longest nights for Shackleton rim sites are ~1.5 days (Mazarico et al. 2011). Aurora's exact night is a training scenario |
| Talking to Earth | Earth sinks and the radio turns to static | Earth's height above a polar horizon changes over the month, so when it is visible depends on the exact site and terrain |
| Shielding | Sparks fizzle in the blue water wall | ~20 g/cm² of water makes a storm shelter |
| Photosynthesis | Lamp OFF −1, DIM ±0, FULL +1 | Respiration and the light compensation point |
| Plants vs radiation | The storm scares Alo, but cold and thirst are the real danger | Plants generally tolerate much higher doses than people (not immunity) |
| Shared resources | The shield water *is* Alo's water | Multi-use water, as in NASA's water-wall concepts |
| Crew first | Running out of air ends the mission | Real flight rules |
| Teamwork | Secrets and the Earth-set silence | Scott Kelly's zinnias; NASA team training |

The lesson in one line: **missions fail from silence.**

### The fun layer

- **Alo's readable states:** cold posture · thirsty drooping leaves · storm stress · a natural yellow bloom at sunrise.
- **Crew reactions:** blankets when it's cold, Rafi in his oversized helmet, Amara blowing bubbles when the air tank is
  full.
- **Juicy feedback:** drops clink into the jar, frost creeps over the glass, the screen shakes in the storm, and the
  sunrise bloom pops with petals and music.
- **Reasons to replay:** the Golden Bloom, harder modes, and a mission patch to print with your team name.

## Stars and endings

Three stars, in the order of real mission priorities: **1. crew safe → 2. base running → 3. Alo blooms.**

- ★ **Crew safe:** a storm dose of 3 or less.
- ★ **Lights on:** the battery never ran out.
- ★ **Alo blooms:** alive at First Light.

| Ending | What happens |
|---|---|
| **Golden Bloom** | Crew safe, lights on, and Alo bursts into a full golden cluster. Rare: the expert goal |
| **Bloom** | Crew safe and Alo alive. A tiny yellow flower opens at sunrise |
| **Alo lost** | The crew made it, but Alo didn't, just like the first Moon sprout in 2019. *Try again?* |
| **Mission stopped** | The air ran out or the crew's storm dose passed the limit, so the flight rules stop the night before anyone is hurt. *Try again?* |

There are many ways to win. Every setting is useful in some winning plan; the point is informed trade-offs, not one
right answer.

## The debrief: astronaut skills

The debrief awards the team skills NASA trains astronauts and flight controllers in (Space Flight Resource Management):

| Badge | Earned when… |
|---|---|
| **Communication** | The team acted on all four secrets |
| **Situational awareness** | The shelter was ready before the alarm |
| **Decision making** | No blackout |
| **Team care** | The crew stayed safe and Alo bloomed |

Then it shows:

1. the night's timeline;
2. **who knew what**, and when;
3. **"what if"**: a replay with one change;
4. **"what was real"**: the measured sunlight map, the storm timeline and the radiation charts measured at the Moon
   and by Curiosity on Mars, each labelled observed, computed or simulated.

## Season 1: *The First Moon Garden*

> **Turn one flower into the first garden on the Moon, in one real Moon year, and find out who left the seeds.**

At First Light, the base's old computer wakes up and plays a message recorded twelve years ago:

> *"If you're hearing this, Alo bloomed. Good. Now Alo needs a friend. — N."*

The night is only Chapter 1. Season 1 follows Alo's family for one Moon year (April 2046 to April 2047) in eight
chapters, each with a new game toy and a new spotlight cadet.

| # | Chapter | Spotlight | What happens | Length |
|:---:|---|---|---|:---:|
| 1 | **Night One** | Everyone | The long night, the storm and the first bloom | 75 min |
| 2 | **Be the Bee** | Mei | No bees on the Moon, so the cadets carry pollen between Alo and Tara on a "bee stick", as astronaut Michael Foale did on Mir in 1997 | 75 min |
| 3 | **Moonquake** | Amara | A moonquake starts an air leak. Alo makes 42 seeds, and a hatch opens: **N.R. · EXPEDITION ZERO** | 85 min |
| 4 | **Into the Cold Trap** | Rafi | A rover trip into a crater colder than −230 °C finds ice, and Noor's seed vault | 90 min |
| 5 | **Shooting Stars** | Ferreira | Under the Geminid meteor shower, Ferreira tells the truth about Expedition Zero. Noor is alive | 85 min |
| 6 | **The Red Ring** | Kai | A real eclipse on 12 January 2047: Earth becomes a black disc in a red ring, and one part of it is the sunrise over Bangladesh | 85 min |
| 7 | **The Great Storm** | Rafi and Ferreira | What if the great storm of July 2012 had hit the Moon? Three waves of particles, then total silence | 105 min |
| 8 | **The Lighthouse** | Everyone | A relay on Malapert Mountain locks on to Earth: *"Hello, Aurora. This is Noor."* The first Moon garden blooms | 120 min |

- **Main story:** 32 missions and 96 scenes, a 720-minute target (10–14 hours), from the canon story [full-game-story/STORY_FULL.md](full-game-story/STORY_FULL.md).
- **The mystery:** who is "N."? **Alo means light. So does Noor.**
- **The ending:** among the flowers grows **cotton**, the plant that froze on the Moon in 2019, alive at sunrise.
  Ferreira: *"You didn't survive the Moon. You grew it."*
- **After the credits:** *"There's one drawer in the vault you haven't opened."* Its label: **MARS**.

<details>
<summary><b>The full Season 1 story (spoilers)</b></summary>

**Chapter 1 · Night One.** Two weeks before the long night, Mei finds an old seed packet at the back of a drawer: two
seeds, the word *Alo* written in Bangla, and one letter, **N.** She plants them both. Then comes the night: no Sun, no
Earth, a real storm… and at First Light, Alo blooms, and Noor's twelve-year-old message plays.

**Chapter 2 · Be the Bee.** A mustard flower can't make seeds alone: it needs pollen from another plant. Alo lives
outside; its partner, Tara, lives inside. There are no bees on the Moon, so the cadets become the bees. Mei remembers
her grandmother, who pollinated apple trees by hand after the bees disappeared. That night, the ground trembles.

**Chapter 3 · Moonquake.** A moonquake, like the one Apollo's seismometers felt near the south pole in 1973, shakes the
base, and air starts leaking. Amara has to find the leak with numbers she can't trust. Alo's pods ripen and its last
petal falls: *"Forty-two seeds. Alo made forty-two seeds."* The quake has cracked open a hatch marked **N.R. ·
EXPEDITION ZERO**: below it lie a frozen garden, twelve years old, and a map to a crater that never sees the Sun.

**Chapter 4 · Into the Cold Trap.** Five months later, Alo's seeds have become a garden of twelve. At midsummer, Rafi
leads a rover expedition down into a crater colder than −230 °C. The headlights find ice in the soil, and a frozen
capsule: **Noor's seed vault**. Inside the lid: *"If you found this, you're ready. Ask Commander Ferreira about
Expedition Zero."*

**Chapter 5 · Shooting Stars.** While the Geminid meteor shower sparks tiny impact flashes across the dark plains,
Ferreira tells the truth. Twelve years ago, she was the youngest engineer of Expedition Zero. A storm broke their relay
radio and they had to leave at sunset. Their gardener, **Dr. Noor Rahman**, stayed to the last minute to hide her
seeds. Then Rao smiles: *"Noor is alive. She has read every one of your reports."*

**Chapter 6 · The Red Ring.** On 12 January 2047, Earth slides in front of the Sun. From the Moon, Earth becomes a
black disc inside a glowing red ring: every sunrise and sunset on Earth at once. Kai, who has feared the dark since he
was little, plans every minute of the eclipse, and isn't afraid. A message arrives: *"I watched a red ring from there
once. — N."* Then a giant sunspot turns towards the Moon.

**Chapter 7 · The Great Storm.** The great storm of July 2012 missed Earth by nine days. What if it had hit the Moon?
Tonight, in a clearly labelled "what if" replay, it does. The cadets protect the crew, the garden and the seeds through
three waves of particles. Ferreira steps back: *"Your call, cadets."* In the Safe Room, Noor's last log plays: *"We're
leaving at last light. I'm calling the seeds Alo, light, so whoever finds them brings the light back."* Then the storm
burns out the radio, and Earth sets.

**Chapter 8 · The Lighthouse.** One Moon year after Night One, the longest night returns. While the base team survives
it, Ferreira and two cadets drive to **Malapert Mountain**, whose summit can almost always see Earth, to fix the relay
Expedition Zero lost. As Earth sinks, the dish locks on: *"Hello, Aurora. This is Noor."* From a rooftop in Bangladesh,
under the Moon, she says: *"You did what I couldn't."* At First Light, the first garden on the Moon blooms yellow.

**From Last Light to First Light:** the game begins at sunset, the last light Noor saw as she left the Moon, and ends
with the first Moon garden's sunrise.

</details>

## Learning goals and curriculum

| # | Big idea | Curriculum link |
|:---:|---|---|
| 1 | Energy in must match energy out, and batteries are limited | NGSS MS-ETS1-1, MS-ETS1-2 (criteria, constraints, comparing solutions) |
| 2 | Why the polar Sun circles the horizon, and why Earth "sets" from the Moon | NGSS MS-ESS1-1 (the Earth-Sun-Moon system) |
| 3 | Plants need light (photosynthesis) and burn sugar in the dark (respiration) | NGSS MS-LS1-6 |
| 4 | Heat costs energy, and cold harms living things | NGSS MS-PS3-3 (thermal energy) |
| 5 | Act on warnings early; shielding is mass between you and the danger | Space-science extension |
| 6 | Share what you know: missions fail from silence | NASA team training (SFRM); jigsaw learning |

The same topics appear in Bangladesh's lower-secondary science (classes 6–8): energy, plants and photosynthesis, and
the solar system.

**Pair it with a real plant.** Grow Wisconsin Fast Plants (*Brassica rapa*) in class. They flower in about 14
days and are the same species as Alo, so students can watch a real "Alo" bloom.

## Planned modes and accessibility

| Mode | For | What changes |
|---|---|---|
| **Solo** | Home, judges | One player switches between all four cadets; the secrets arrive in each cadet's inbox |
| **Family** | Ages 6+ with an adult | No action timers, hints always on, a gentler storm |
| **Cadet** (default) | Ages 10–15 | The full night |
| **Engineer** | Teens, adults, judges | Real units (1 sun-drop ≈ 10 kWh, 1 shift ≈ 7.2 h, g/cm² of shielding) and the real data charts |
| **Class** | One projector, four role groups | Printed role cards and sealed secret envelopes; everyone discusses, each role approves its setting |

**Accessibility goals:**

- English captions for every line, with readable text and speaker/origin labels.
- Icons and words together, never colour alone; large, readable text.
- No action needs rapid button presses, and Family Mode has no timers.
- A reduce-shaking option.
- Works offline on low-end classroom laptops.

**Architecture:** the simulation is separate from the graphics: one authoritative state, a pure preview/step
function, and every number in a data file tagged with its source. Godot 4.7 with the Forward+ renderer, LODs and a
Compatibility fallback for older classroom hardware.
