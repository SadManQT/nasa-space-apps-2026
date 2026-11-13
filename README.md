# Last Light Academy

**Mission Control in a classroom. Four cadets, one Moon base, one long night, and a small mustard plant that must live until sunrise.**

NASA Space Apps Challenge 2026 · Challenge: **[Build a Junior Astronaut Mission Trainer](https://www.spaceappschallenge.org/2026/challenges/build-a-junior-astronaut-mission-trainer/)** · Team **The Last BrainCell** · Dhaka, Bangladesh

*An independent team project. It is not endorsed by NASA and uses no NASA logos.*

![The crew around the Mission Table at Aurora Station](docs/media/commons.png)

| | |
|---|---|
| **240-second video** | *link added after upload* |
| **30-second video** | *link added after upload* |
| **Play it** | [Windows and macOS builds](https://github.com/SadManQT/nasa-space-apps-2026/releases) |
| **Project page text** | [docs/SUBMISSION.md](docs/SUBMISSION.md) |

---

## The problem

Children learn *what* astronauts need: air, power, food, shelter. Almost nothing lets them practise the hard part, which is that these needs fight each other. The power that warms the crew is the power that makes their air. The water that shields them from a solar storm is the water the plants drink.

The places where young people do practise this, such as Space Camp or a Challenger Learning Center, cost a lot and are far away. Bangladesh has none, and most school-age children here have no internet at home.

## Our answer

**Last Light Academy** is a free, offline 3D game for ages 10 to 15. You and up to three friends run Aurora Station at the Moon's south pole. The Sun sets for 36 hours. You plan the night shift by shift, try each plan before you lock it in, and then live with it.

What makes it different:

1. **Four players, one laptop, no internet.** In Class mode each cadet holds facts the others need, and every decision locks in only when all four sign it. A whole class can run a mission in one lesson on a school computer lab.
2. **Real history, replayed.** The storm that hits the base is the real solar storm of 10 September 2017, with its real 70 minutes of warning. The length of the night and the positions of the Sun and Earth come from NASA terrain and orbit data.
3. **Every number shows where it came from.** Data Cards name the NASA source and label each value *Observed*, *Computed* or *Training assumption*, so learners practise asking "how do we know?"
4. **Something living to protect.** Alo is *Brassica rapa*, the mustard grown in Bangladesh every winter. A trade-off is only felt when it costs something you care about.

| The Mission Table: plan, try it, lock it in | A Data Card: the source behind a number |
|---|---|
| ![The Seven Shifts planner](docs/media/seven_shifts.png) | ![A NASA Data Card](docs/media/data_card.png) |

## How it answers the challenge

The challenge asks for a game in which students *"run a lunar or Martian outpost, balancing competing demands like life support, radiation shielding, power, and food production"*. Those four demands are always on screen.

| Demand | What the player manages | Real data behind it |
|---|---|---|
| **Life support** | An air tank of 10 units. Four crew breathe 1 unit per shift. Making air costs power. | NASA Life Support Baseline Values (BVAD, 2022): 0.895 kg of oxygen per person per day |
| **Radiation shielding** | A water wall plus supply boxes. At the storm alarm: pump water, stack boxes, or wait. | NASA DONKI and NOAA GOES-13 records of the 10 Sep 2017 storm; NASA Langley shielding studies (20 g/cm² of water) |
| **Power** | A battery of 20 units. Sunlight adds 8 per shift by day and nothing at night. | NASA Langley 10 kW south-pole solar array study; LRO LOLA illumination study; JPL Horizons |
| **Food production** | The garden, rations and Alo. Light costs power. Water is shared with the shield. | NASA BVAD food rates; NASA OSDR *Brassica rapa* on the ISS; seed-to-seed growth on Mir |

Eight chapters follow one Moon year: pollination by hand, an air leak after a moonquake, a rover trip into a cold trap, meteor flashes, a total lunar eclipse, a "what if" super-storm, and a relay climb to bring back the link to Earth. [docs/SCIENCE_AND_DATA.md](docs/SCIENCE_AND_DATA.md) traces every puzzle to its dataset.

## NASA data

The game ships small offline extracts of 29 NASA and partner sources in [`game/resources/data/nasa/`](game/resources/data/nasa/). Each keeps its URL, ID or DOI, retrieval date, licence, the values used and the formulas. No AI model produced a data value: a plain Python script downloads the records ([production/tools/fetch_nasa_data.py](production/tools/fetch_nasa_data.py)).

- **Storm and radiation:** NASA DONKI, LRO CRaTER, NASA STEREO-A, NASA Langley shielding studies
- **Light, sky and ground:** LRO LOLA elevation and illumination, JPL Horizons, the NASA lunar eclipse catalog
- **Life support, power and food:** NASA BVAD, the NASA 10 kW relocatable solar array, NASA OSDR plant experiments
- **The Moon's surface:** Apollo moonquake records, NASA Lunar Impact Monitoring, LCROSS, LRO Diviner, VIPER
- **Partner data, labelled with its agency:** NOAA GOES-13, USGS/IAU, ESA, ISRO Chandrayaan-1, JAXA Kaguya, CNSA Chang'e-4, Wisconsin Fast Plants

Aurora Station, the cadets, Alo and the 2046 dates are fiction. The 2017 storm is a replay of real timing. The 2012 storm reaching the Moon in Chapter 7 is a labelled "what if".

## Play it

**Download** a Windows or macOS build from [Releases](https://github.com/SadManQT/nasa-space-apps-2026/releases).

- **Windows:** unzip, keep `LastLightAcademy.exe` and `LastLightAcademy.pck` together, run the EXE.
- **macOS:** unzip, move the app to Applications and open it. The build is not signed. If macOS blocks it, use **Privacy & Security → Open Anyway**.

**Run from source** (Godot 4.7):

```bash
git lfs install
git clone https://github.com/SadManQT/nasa-space-apps-2026.git
```

Open `game/project.godot` in Godot and press **Play** (F5). The first import takes a few minutes.

**Controls:** WASD to walk, mouse to look, **E** to use, **H** for help, **Esc** to pause. Captions are on and nothing is timed. Settings can make text 1.5 times larger and reduce motion.

**Five-minute route for judges:** title screen → **New Expedition** → Solo or Class → follow the blue ◇ marker to the Mission Table and press **E**. Plan a shift, press **Try it**, then **Lock in**. Open a **Data Card** to see the NASA source behind a number.

**Tests:** `game/tools/run_tests.sh` runs all 140 automated suites, including a walk through all 96 scenes.

## Tested with young players

We gave the game to 18 learners under 15. Their plainest feedback was that the instructions were too hard to follow, so we rewrote every on-screen instruction in words a nine-year-old can read and added step-by-step help to the first puzzles.

## Use of AI

We used AI tools and we disclose them. The team wrote the story, the characters and every line of dialogue, designed every puzzle and its numbers, mapped the NASA data to the game, directed the art, and approved or rejected every result.

| Tool | Maker | What it helped with |
|---|---|---|
| **Claude** | Anthropic | Code, tests, data scripts and documentation, written to our designs |
| **ChatGPT** (including Codex and GPT Image) | OpenAI | Code, code review and a few image edits |
| **Gemini** (including Nano Banana and Veo) | Google | Concept art, character sheets, cutscene frames and one video shot |
| **ElevenLabs** | ElevenLabs | Character voices, music and sound effects |

The complete list of generation tools, with what each made and sample prompts, is in [docs/AI_USE.md](docs/AI_USE.md). Every generation is logged in [production/AI_PROMPT_LOG.md](production/AI_PROMPT_LOG.md).

## Licence and credits

Our code and content are released under the **[Apache License 2.0](LICENSE)**. [CREDITS.md](CREDITS.md) credits every dataset, paper, tool, font and asset.

## Team

Team **The Last BrainCell** · Dhaka, Bangladesh · [Space Apps team page](https://www.spaceappschallenge.org/2026/find-a-team/the-last-braincell)

| Name | Role |
|---|---|
| Nafis Mohtasim Ramim | Team leader · interface and player systems |
| Khandaker Shadman Sakib Siddiquee | Producer · art and media · integration |
| Md. Asif Iqbal | Science and accessibility review |
| Abu Sayem Mohammed Tanvir | Testing and playtests |
| Shahariar Rahman Shanto | Presenter |
| MD Atik Khan | Gameplay, Moon systems and builds |

## What is in this repository

| Path | What it is |
|---|---|
| [`game/`](game/) | The Godot 4.7 project: scripts, scenes, assets, offline NASA data and tests |
| [`docs/`](docs/) | Project page text, science and data mapping, AI use, classroom role cards |
| [`full-game-story/`](full-game-story/) | The story: 8 chapters, 96 scenes |
| [`game-design/`](game-design/) | Puzzle rules and numbers, characters, world and science accuracy |
| [`production/`](production/) | Data and asset tools, art bible, AI prompt log, video files |
| [`CREDITS.md`](CREDITS.md), [`LICENSE`](LICENSE) | Credits and licence |
