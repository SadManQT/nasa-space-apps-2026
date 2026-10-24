# Similar games, NASA data for the game, and learning research

Researched on 6 October 2026 for Team The Last BrainCell. Statements labelled **[Judgement]** are our opinion; everything else has a source.

---

## 1. Existing games and programmes

| Product | Audience | How it plays | What's missing compared with our idea |
|---|---|---|---|
| [NASA *Moonbase Alpha*](https://en.wikipedia.org/wiki/Moonbase_Alpha) (2010) | Teens and up; PC (Steam) | 1–6 players repair life support at a 2032 lunar outpost within 25 minutes ([phys.org](https://phys.org/news/2010-07-nasa-videogame-moonbase-alpha.html)) | A single repair crisis; no ongoing balancing; needs a gaming PC |
| [Minecraft Education: Artemis](https://www.nasa.gov/learning-resources/take-the-next-giant-leap-with-nasa-and-minecraft/) | Ages 8+ | Build a rocket, code an Orion landing | About getting to the Moon, not running a base; needs licences |
| [JPL "Marsbound!"](https://www.jpl.nasa.gov/edu/resources/lesson-plan/marsbound-mission-to-the-red-planet/) | Grade 3+ | Pick mission parts within mass, power and budget limits | Trade-offs happen once, at design time; no live operations |
| [JPL Mars Rover Driver board game](https://www.jpl.nasa.gov/edu/resources/lesson-plan/mars-rover-driver-board-game/) | Primary/middle school | Rover, scientist and engineer roles | About a rover, not a habitat |
| [ESA Moon Camp](https://www.esa.int/Education/Moon_Camp/What_is_the_Moon_Camp_Challenge2) | Ages 6–19; 5,354 students from 39 countries in 2023 | Design a Moon base in Tinkercad or Fusion 360 | A design contest that lasts weeks, not a game; nothing goes wrong |
| [Challenger Learning Center missions](https://en.wikipedia.org/wiki/Challenger_Center_for_Space_Science_Education) | Upper primary/middle school | 2-hour simulation; the class splits between Mission Control and the station, with teams such as Life Support and Navigation | **The closest model to ours**, but it needs a physical centre. Bangladesh has none |
| [Space Camp, Huntsville](https://airandspace.si.edu/stories/editorial/sleepaway-camp-make-it-space) | Ages 9+ | Assigned roles; staff inject problems during timed missions | Expensive; USA only |
| [Kerbal Space Program / KerbalEdu](https://wiki.kerbalspaceprogram.com/wiki/KerbalEdu) | Teens and up; paid | Build and fly rockets with real orbital physics | Flight, not life support; steep learning curve |
| [Surviving Mars](https://en.wikipedia.org/wiki/Surviving_Mars) | Teens and adults | Colony builder: oxygen, water, power, dust storms | Solo; hours long; commercial |
| [Oxygen Not Included](https://en.wikipedia.org/wiki/Oxygen_Not_Included) | Teens and adults | Deep colony sim with gas, heat and power | Solo; very complex |
| [Spaceteam](https://en.wikipedia.org/wiki/Spaceteam) | 2–4 players, all ages | Every phone shows a control panel, but your instructions appear on *other* players' screens, so you shout | Proves split information is fun; no science |
| [Keep Talking and Nobody Explodes](https://en.wikipedia.org/wiki/Keep_Talking_and_Nobody_Explodes) | Teens and up | One player sees the bomb; the others hold the manual | Same pattern; no science |
| [Artemis Spaceship Bridge Simulator](https://en.wikipedia.org/wiki/Artemis:_Spaceship_Bridge_Simulator) | 3–8 players, networked PCs | One station per player; engineering shares power between systems | Sci-fi combat; needs several PCs |
| [Pandemic](https://en.wikipedia.org/wiki/Pandemic_(board_game)) | Ages 8+ | Cooperative board game with special roles and escalating events | Not about space; its event deck is a useful model |
| [FTL](https://en.wikipedia.org/wiki/FTL:_Faster_Than_Light) | Teens and up | Shift limited reactor power between oxygen, shields and engines | Solo sci-fi; its "power bar" interface is worth borrowing |

**2026 entries already public for our exact challenge:**
- [Little Orbit](https://github.com/Yoriichi-0u0/little-orbit)
  - A solo game for ages 10+, lasting 15–25 minutes (14 turns), set on a Moon "polar ridge" or on Mars.
  - It has 8 hardware types and 5 linked resources, uses a predict-then-observe loop, and cites 13 NASA/JPL sources.
  - Its README says it has **no cooperative element**.
- [ESPERANZA Outpost](https://github.com/engimine/esperanza-outpost): a Mars browser game covering food, air and safety, with dust storms and radiation alerts.
- [Lunar Ops](https://github.com/aleexxeyy/lunar-ops) and [Team B-612](https://github.com/farhan366/Team-B-612): their design details could not be read.

**[Judgement] The gap.** No product combines all four of these:
1. a class team of 4 on one cheap device;
2. real split information about real life-support systems;
3. events replayed from real NASA records;
4. a built-in debrief.

Challenger Centers have the roles but need buildings. Commercial games have the systems but are solo and hours long.

---

## 2. NASA data that can drive the game

| Dataset | Numbers we can use | Source | Mechanic |
|---|---|---|---|
| **LRO LOLA / LROC (sunlight)** | The sunniest spots near Shackleton are lit ~94% of the year, and their longest darkness lasts ~43 h. The Shackleton–de Gerlache connecting ridge is lit ~88–92% of the time at 2 m height | [LROC](https://www.lroc.asu.edu/images/789); [Gläser et al. 2014](https://www.sciencedirect.com/science/article/abs/pii/S0019103514004278); [Mazarico et al. 2011](https://ntrs.nasa.gov/citations/20120010094); elevation models from [PGDA](https://pgda.gsfc.nasa.gov/products/78) | The night's length, Last Light, the horizon strip |
| **Earth visibility** | From the south pole, Earth is visible about half of each month; best-site direct-to-Earth availability is ~51% | [JPL IPN PR 42-176](https://ipnpr.jpl.nasa.gov/progress_report/42-176/176C.pdf); [Speyerer & Robinson, LEAG 2025](https://www.hou.usra.edu/meetings/leag2025/pdf/5069.pdf) | Earth-set: hints stop |
| **DONKI (space weather)** | X9.3 flare peaked 6 Sep 2017 at 12:02 UT. X8.2 flare began 10 Sep 2017 at 15:35 UT and peaked at 16:06 UT. The >100 MeV proton event started 16:25 UT; >10 MeV at 16:45 UT. The neutron-monitor ground-level onset (GLE 72) came at ~16:15 UT. The 6 Sep CME moved at 1,238 km/s | DONKI API (no key): `https://ccmc.gsfc.nasa.gov/DONKI-API/get/{FLR,CME,SEP,GST}`; [GLE 72 study](https://arxiv.org/abs/1810.10536); [Space Weather paper](https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2018SW002085) | The storm event and its timing |
| **Curiosity RAD (Mars)** | Background ~0.67 mSv/day. On 11 Sep 2017 the same storm more than doubled the surface dose, peaking at 2–3× background for ~12 h | [JPL](https://www.jpl.nasa.gov/news/nasa-watches-mars-light-up-during-epic-solar-storm/); [Zeitlin 2018](https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2018GL077760); [Ehresmann 2018](https://agupubs.onlinelibrary.wiley.com/doi/10.1029/2018GL077801) | "Same storm, two worlds" debrief |
| **CRaTER (radiation dose at the Moon)** | ~0.22–0.27 mGy/day in lunar orbit; ~1,369 µSv/day on the lunar surface (measured by China's Chang'e-4, peer-reviewed) | [Science Advances 2020](https://www.science.org/doi/10.1126/sciadv.aaz1334) | Engineer Mode dose context |
| **NASA BVAD (life support)** | Per crew member per day: O₂ 0.895 kg, CO₂ 1.085 kg, drinking water 3.217 kg, food 0.800 kg, 12.78 MJ (Table 3-31) | [BVAD 2022 (PDF)](https://ntrs.nasa.gov/api/citations/20210024855/downloads/BVAD_2.15.22-final.pdf) | Rates behind the bars |
| **ISS life support** | The oxygen generator makes 2.3–9.2 kg O₂/day (5.4 nominal), enough for up to 6 crew | [NASA ECLSS fact sheet](https://www.nasa.gov/wp-content/uploads/2015/03/104840main_eclss.pdf) | The oxygen maker dial |
| **Veggie / Advanced Plant Habitat** | Crew first ate space lettuce on 10 Aug 2015. Chile peppers took 137 days | [NPR](https://www.npr.org/sections/thetwo-way/2015/08/10/431239435/one-small-bite-for-man-nasa-astronauts-to-eat-space-grown-food); [NASA](https://www.nasa.gov/missions/station/iss-research/chile-peppers-start-spicing-up-the-space-station/) | Slow food payoff |
| **Water as a shield** | Hydrogen-rich materials such as water shield best, especially against solar particle events | [NASA Water Walls](https://ntrs.nasa.gov/api/citations/20190001191/downloads/20190001191.pdf); [NASA lunar radiation talk](https://ntrs.nasa.gov/api/citations/20210009760/downloads/Clowdsley_Lunar_Radiation_Talk_v2.pdf) | The water wall |
| **Orion storm shelter** | The crew builds a shelter from stowage bags within an hour and may stay in it up to 24 h | [NASA](https://www.nasa.gov/missions/artemis/orion/scientists-and-engineers-evaluate-orion-radiation-protection-plan/) | The supply wall |
| **LRO Diviner (cold)** | The coldest spot measured is ~26 K, in Hermite crater; the floor of Shackleton is ~88–90 K | [Diviner](https://www.diviner.ucla.edu/science) | Night heat cost |
| **Artemis Base Camp, Fission Surface Power** | A habitat for 4 crew. The fission power unit gives 40 kWe for 10 years | [Space.com](https://www.space.com/nasa-plans-artemis-moon-base-beyond-2024.html); [NASA FSP](https://www.nasa.gov/humans-in-space/fission-system-to-power-exploration-on-the-moons-surface-and-beyond/) | 4 crew = 4 players; roadmap |
| **South-pole moonquakes** | Shallow moonquakes could shake the ground strongly and cause landslides near Artemis regions | Watters et al. 2024; [Smithsonian](https://dashboard.si.edu/es/newsdesk/releases/shrinking-moon-causes-temblors-and-faults-lunar-south-polar-region) | Optional event card later |

**DONKI note (checked 6 Oct 2026):** the old address `kauai.ccmc.gsfc.nasa.gov/DONKI/WS/get/...` now returns a 301 redirect. The new `ccmc.gsfc.nasa.gov/DONKI-API/get/...` worked. A third-party report says `api.nasa.gov/DONKI` was retired on 30 Sep 2026. **Bundle the 2017 records inside the game so it works offline.**

---

## 3. Learning research (ages 10–16)

- **Group play beats solo play.** Wouters et al. (2013) meta-analysed 39 studies:
  - Serious games beat conventional teaching for learning (d = 0.29) and retention (d = 0.36).
  - Learners in groups learned more than solo players.
  - Gains were bigger when the game was combined with other teaching and played over several sessions.
  - [Paper (PDF)](https://ocw.metu.edu.tr/pluginfile.php/11786/mod_resource/content/1/A%20Meta-Analysis%20of%20the%20Cognitive%20and%20Motivational%20Effects%20of%20Serious%20Games.pdf)
- **Jigsaw classrooms.** Each student holds one "expert" piece, so the group needs every member. Studies report better self-esteem, empathy, motivation and achievement, especially for disadvantaged students ([Harvard ABLConnect](https://ablconnect.harvard.edu/jigsaw-research); [Aronson & Bridgeman 1979](https://journals.sagepub.com/doi/10.1177/014616727900500405)). **Our secrets are the jigsaw method in game form.**
- **Productive failure.** Struggling with a problem before being taught improved conceptual understanding and transfer: d = 0.36 overall, and up to g = 0.58 when done well (53 studies; [ERIC](https://eric.ed.gov/?id=EJ1308129)). This supports "fail the mission, then debrief".
- **The debrief matters most.** Crookall calls debriefing the most important part of a simulation ([HAL](https://hal.science/hal-03904518/)).
- **Connectivity.** 63% of Bangladesh's school-age children have no internet at home. Household access ranges from 8.7% in the poorest fifth of families to 75.3% in the richest fifth ([UNICEF Bangladesh](https://www.unicef.org/bangladesh/en/press-releases/two-thirds-worlds-school-age-children-have-no-internet-access-home-new-unicef-itu)).

**[Judgement] What this means for the design:**
- One class period: about 25 minutes of play and 10 minutes of debrief.
- Replayable across 2–3 lessons.
- One offline file.
- Bangla and English.
- A debrief that shows who knew what, and when.

---

## 4. Creative hooks, and whether they exist elsewhere

| Hook | Found elsewhere? |
|---|---|
| The Sun is the clock (real LOLA/LROC sunlight) | Not found in educational games. Little Orbit uses a fictional "polar ridge" |
| Survive September 2017 (a dated DONKI replay) | Generic radiation alerts exist (ESPERANZA); a dated NASA-record replay was not found |
| Same storm, two worlds (Curiosity RAD) | Not found |
| Split consoles (jigsaw) with real life-support data | The pattern exists (Spaceteam, Challenger Centers) but not with real life-support data in a classroom game |
| Teacher as Mission Control | Challenger Centers and Space Camp do it with staff and buildings; no free offline digital version was found |
| Cadet / Engineer modes | Moon Camp has age tiers, but for design tasks, not gameplay |
| A replay of each player's hidden information in the debrief | Not found |

**[Judgement] Verdict.**
- **The theme is not original.** Every entry will balance power, air, food and radiation.
- **The combination is.** It becomes clearly original if the judges see three things within the first minute:
  1. the real sunlight schedule;
  2. a named, dated real storm;
  3. a debrief that replays who knew what.
- Present it as a free, offline, Bangla-capable Challenger-Center mission for classrooms that have no space centre.
