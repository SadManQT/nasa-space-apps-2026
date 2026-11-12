# Credits — Last Light Academy

Team The Last BrainCell (Bangladesh) · NASA Space Apps Challenge 2026 · *Build a Junior Astronaut Mission Trainer*

Our own code and content are released under the **Apache License 2.0** ([LICENSE](LICENSE)). Everything below keeps its own licence. This file credits every source we use, free ones and generated content included, as the Space Apps terms require ("All resources, even open source resources, must be cited"). Last checked **4 November 2026**; every URL below answered when checked.

NASA does not endorse this project. The game uses no NASA logos, insignia or branding.

## 1. Team

The story, characters, dialogue, puzzle rules and numbers, science mapping, art direction and every approval are the team's work (details: [docs/AI_USE.md](docs/AI_USE.md), "What the team did itself"). Contributors named in the repository history so far: Sadman Sakib (`sadmanqt`), Abu Sayem Mohammed Tanvir, MD Atik Khan and the account `2405167-hub`. The full roster with roles goes in `docs/TEAM.md` (team board task), which is the source for the in-game team credits.

## 2. Engine and tools

| Tool | Licence | Used for | Ships in the game? | Link |
|---|---|---|---|---|
| **Godot Engine 4.7** | MIT | The game engine | Yes: the MIT notice and Godot's third-party notices must appear in the build (see §9) | <https://godotengine.org/license/> |
| **gohud** | MIT, copyright 2026 JaeHo Song; bundled components retain their own notices | Runtime UI widgets, themes and icons | Yes: native ZIPs include its LICENSE, third-party notices (including Tabler Icons), and bundled font OFL notices under `THIRD_PARTY_NOTICES/gohud/` | [Supplied notices](game/addons/gohud/THIRD_PARTY_NOTICES.md) |
| **Blender** | GNU GPL (tool only; files made with it are ours) | Model clean-up, rigging fixes, previews; the pitch video's scenes | No | <https://www.blender.org/about/license/> |
| **FFmpeg** | LGPL/GPL (tool only) | Cutscene assembly (dissolves, captions, music ducking) in `production/tools/compose_cutscene.py` | No | <https://ffmpeg.org/legal.html> |
| **Python** (standard library) | PSF License (tool only) | Pipeline scripts, `production/tools/fetch_nasa_data.py` | No | <https://docs.python.org/3/license.html> |
| **Adobe Mixamo** | Adobe Mixamo terms (royalty-free in projects; raw clips not redistributed) | Character animations in the pitch video only | No | <https://www.mixamo.com/> |

## 3. Fonts (runtime update, 12 November 2026)

- **The current UI uses Saira Semi Condensed and Inter**, installed in `game/assets/fonts/ui/`. Saira is copyright 2016 The Saira Project Authors (reserved font name "Saira"); Inter is copyright 2020 The Inter Project Authors. Both ship under the SIL Open Font License 1.1. The supplied notices are [OFL_Saira.txt](game/assets/fonts/ui/OFL_Saira.txt) and [OFL_Inter.txt](game/assets/fonts/ui/OFL_Inter.txt); native distribution ZIPs also include their complete, unchanged text under `FONT_LICENSES/`.
- **Godot's built-in fallback font is Open Sans** (© 2020 The Open Sans Project Authors, SIL Open Font License 1.1), compiled into the engine. Its notice is part of Godot's third-party copyright list. <https://github.com/googlefonts/opensans>
- **The pitch video uses Baloo Da 2** (Ek Type, SIL Open Font License 1.1). It is not in the game. <https://fonts.google.com/specimen/Baloo+Da+2>

## 4. AI tools and generated content

Generated assets were produced with the tools below on accounts and plans the team already holds (no tool was bought for this project), then selected, checked against the art bible, cleaned up and edited by the team: Blender clean-up and rigging fixes, flag patches, toon faces drawn by script, cutscene edits, captions and mixing. Every generation is logged with its exact prompt in [production/AI_PROMPT_LOG.md](production/AI_PROMPT_LOG.md); the full disclosure is [docs/AI_USE.md](docs/AI_USE.md).

| Tool | Maker | What it made |
|---|---|---|
| **Tripo AI** | VAST | 3D models of the five characters, 24 plants and props, the 20 pitch-video models reused in the game; character skeletons |
| **Meshy** | Meshy | Motion-capture animation clips from the Meshy animation library (retargeted, 42 per character) and five text-to-motion story actions |
| **ElevenLabs** | ElevenLabs | Character voices (eleven_v4) and three music cues (eleven_music_v2_5) in the cutscenes; the Flows workspace that ran the image and video models |
| **Nano Banana Pro** (Gemini 3 Pro Image) | Google | Concept art, turnaround sheets, screen portraits, cutscene start frames |
| **GPT Image 2.5 Sunburst** | OpenAI | A few cutscene start-frame edits |
| **Topaz Image Upscale v2** | Topaz Labs | 4× upscales of turnaround views before 3D |
| **Seedance 2.5** | ByteDance | Cutscene video shots from our start frames (via ElevenLabs Flows) |
| **Claude Code** | Anthropic | Pipeline scripts, prompts, documentation, data fixtures, orchestration; the pitch video's Blender scripts, motion graphics, synthesized music and sound effects and edit |
| **Codex** | OpenAI | Game code, code review, bug hunting |
| **Antigravity** | Google | One asset-review second opinion (rejected); nothing in the game |

Google Veo 3.1 (in Google Flow) made one shot: the 6-second mustard field that opens CS-01 (M1-52; production/ai_log_parts/M1-52.md).

## 5. Every file in `game/assets`

`.import` and `.uid` files next to each asset are Godot metadata generated by the editor. Each asset folder holds one file named after the folder.

| `game/assets/` | Assets | Made with | Log rows in AI_PROMPT_LOG.md |
|---|---|---|---|
| `characters/` | CH_Kai, CH_Amara, CH_Mei, CH_Rafi, CH_Ferreira | Nano Banana Pro turnarounds (Topaz upscale) → Tripo multiview 3D and skeleton → Meshy library clips and story motions → team Blender clean-up; faces drawn by script | 2026-10-26 *Story motions for all five characters*; 2026-10-27 *v7 style tests*, *v7 anime turnarounds*, *v8 turnaround sheets*, *v8 side views*, *v8 character 3D models*, *v8 Mei 3D model*, *retakes*, *v8 final skeletons*, *v7 motion-source rigs and clips*, *Inspect v3 story motion*, *v7 anime face layers* |
| `plants/` | PL_Alo_Bud, PL_Alo_Bloom, PL_Alo_Pods, PL_Tara_Bloom, PL_Cotton_Young, PL_ZeroSeedlingTray | Nano Banana Pro concepts → Tripo image-to-3D → Blender clean-up | 2026-10-25 *Plant and prop concepts*, *15 props and plants* |
| `plants/` | PL_CropRack | Tripo model made for the pitch video, reused | 2026-10-25 *22 reused props* |
| `props/` | PR_GrowthChamber, PR_MissionTable, PR_VaultCase, PR_SeedCase, PR_Glovebox, PR_MalapertRelay, PR_SurveyBeacon, PR_CrewSeat, PR_HandLight, PR_PollinationKit | Nano Banana Pro concepts (Glovebox, CrewSeat, PollinationKit through Tripo's image tool) → Tripo image-to-3D | 2026-10-25 *Plant and prop concepts*, *Glovebox, crew seat, pollination kit concepts*, *15 props and plants*, *PR_PollinationKit 3D model* |
| `props/` | PR_IceScanner, PR_ManualGauge, PR_RepairClamp, PR_RelayController, PR_UplinkFeedthrough, PR_SampleHolder, PR_SeedPacket, PR_Mug | Nano Banana Pro concepts → Tripo image-to-3D | 2026-10-26 *8 prop concepts*, *3D models of the 8 props above* |
| `props/` | PR_ControlConsole, PR_PowerPanel, PR_BatteryJar, PR_OxygenUnit, PR_WaterValve, PR_WaterWallPanel, PR_HatchDoor, PR_SupplyBundles, PR_Dosimeter, PR_Recorder2034, PR_Helmet, PR_CrewBunk, PR_AnnexDrum | Tripo models made for the pitch video (7–10 Oct), reused | 2026-10-25 *22 reused props* (original pitch prompts were not recorded) |
| `environment/` | EN_CorridorSegment, EN_ExteriorModule, EN_SolarMast | Tripo models made for the pitch video, reused | 2026-10-25 *22 reused props* |
| `vehicles/` | VH_Rover, VH_ReliefLander, VH_ZeroAscent | Tripo models made for the pitch video, reused | 2026-10-25 *22 reused props* |
| `cutscenes/` | CS-01_Arrival.ogv, CS-02_The_Horizon_Closes_One_Door.ogv, CS-03_Alo_Needs_a_Friend.ogv | Nano Banana Pro start frames → Seedance 2.5 shots (three refused shots are ffmpeg push-ins, no AI) + ElevenLabs voices (Kai, Amara, Mei, Ferreira, N.) and music; edited, captioned and mixed by the team pipeline (FFmpeg) | 2026-10-27 *Cutscenes v7 start frames* (both rows), *Cutscene v7 video* (both rows), *CS-02-C, CS-03-B, CS-03-C (refused generations)*, *Cutscene v7 voice lines*, *Cutscene v7 music*, *Cutscenes … assembled* |
| `cutscenes/README.md`, `README.md` | Folder notes | Written by the team | — |
| `ui/portraits/` | CH_Rao_screen.png, CH_Noor_present_portrait.png, CH_Noor_2034_portrait.png | Nano Banana Pro | 2026-10-27 *v7 screen-only portraits* |

The spoken words in every cutscene are the team's story text ([full-game-story/STORY_FULL.md](full-game-story/STORY_FULL.md)) word for word.

## 6. NASA and partner data

The game's numbers come from these datasets. The mapping to each puzzle is [docs/SCIENCE_AND_DATA.md](docs/SCIENCE_AND_DATA.md) §B; the offline extracts with full citations are in `game/resources/data/nasa/`.

**NASA**
- DONKI space-weather records, Sep 2017 and Jul 2012 — NASA GSFC Community Coordinated Modeling Center — <https://ccmc.gsfc.nasa.gov/tools/DONKI/>
- STEREO-A IMPACT/HET proton flux — NASA SPDF CDAWeb — <https://cdaweb.gsfc.nasa.gov/hapi>
- LRO CRaTER daily dose rates — CRaTER team, University of New Hampshire; NASA PDS PPI — <https://crater-products.sr.unh.edu/>
- LRO LOLA polar illumination (Mazarico et al. 2011) — NASA GSFC — <https://ntrs.nasa.gov/citations/20120010094>
- JPL Horizons ephemerides (Sun and Earth from the south pole and Mons Malapert) — NASA JPL — <https://ssd.jpl.nasa.gov/horizons/>
- Lunar eclipse catalog 2001–2100 (F. Espenak) — NASA GSFC — <https://eclipse.gsfc.nasa.gov/LEcat5/LE2001-2100.html>
- Life Support Baseline Values and Assumptions Document, Rev 2 (2022) — NASA JSC — <https://ntrs.nasa.gov/citations/20210024855>
- Relocatable 10 kW Solar Array for Lunar South Pole Missions; Vertical Solar Array Technology — NASA LaRC — <https://ntrs.nasa.gov/citations/20210011743>, <https://ntrs.nasa.gov/citations/20220013210>
- Protecting Astronauts from Space Radiation on the Lunar Surface (Clowdsley 2021) — NASA LaRC — <https://ntrs.nasa.gov/citations/20210009760>
- Apollo shallow moonquake catalog (Nakamura 1979) — NASA PDS Geosciences Node — <https://pds-geosciences.wustl.edu/lunar/urn-nasa-pds-apollo_seismic_event_catalog/>
- Lunar Impact Monitoring — NASA MSFC Meteoroid Environment Office — <https://www.nasa.gov/meteoroid-environment-office/lunar-impact-monitoring/>
- LCROSS (Colaprete et al. 2010) — NASA ARC — <https://science.nasa.gov/mission/lcross/>
- LRO Diviner (Paige et al. 2010) — NASA LRO / UCLA — <https://www.diviner.ucla.edu/science>
- VIPER rover — NASA — <https://science.nasa.gov/mission/viper/rover-and-instruments>
- Open Science Data Repository, OSD-59 and OSD-412 (*Brassica rapa* on the ISS) — NASA GeneLab — <https://osdr.nasa.gov/bio/repo/data/studies/OSD-59>
- Seed-to-seed *Brassica rapa* on Mir (Musgrave et al.) — NASA NTRS — <https://ntrs.nasa.gov/citations/20040141614>
- Lunar pole illumination and communications maps (Bryant 2009) — NASA JPL IPN — <https://ipnpr.jpl.nasa.gov/progress_report/42-176/176C.pdf>

**Partner agencies and institutions**
- GOES-13 proton flux, Sep 2017 — NOAA NCEI — <https://www.ncei.noaa.gov/products/goes-1-15/space-weather-instruments>
- Gazetteer of Planetary Nomenclature — USGS Astrogeology / IAU WGPSN — <https://planetarynames.wr.usgs.gov/>
- Moonlight lunar communications — ESA — <https://www.esa.int/Applications/Connectivity_and_Secure_Communications/Moonlight2>
- Moon Mineralogy Mapper on Chandrayaan-1 (Li et al. 2018) — ISRO with NASA — <https://doi.org/10.1073/pnas.1802345115>
- SELENE (Kaguya) Terrain Camera (Haruyama et al. 2008) — JAXA — <https://darts.isas.jaxa.jp/planet/pdap/selene/>
- Chang'e-4 Lunar Lander Neutrons and Dosimetry (Zhang et al. 2020) — CNSA, Kiel University — <https://doi.org/10.1126/sciadv.aaz1334>
- Chang'e-4 cotton experiment (Qiu et al. 2021) — CNSA, Chongqing University — <https://doi.org/10.3390/ijms222111723>
- Wisconsin Fast Plants (facts quoted; their resources are CC BY-NC-SA) — University of Wisconsin–Madison — <https://fastplants.org/frequently-asked-questions/>

## 7. Research papers and references

The game's numbers rest on these publications (DOIs checked 3 Nov 2026):
- Mazarico, E. et al. (2011) Illumination conditions of the lunar polar regions using LOLA topography. *Icarus* 211. doi:10.1016/j.icarus.2010.10.030
- Colaprete, A. et al. (2010) Detection of water in the LCROSS ejecta plume. *Science* 330. doi:10.1126/science.1186986
- Paige, D.A. et al. (2010) Diviner Lunar Radiometer observations of cold traps in the Moon's south polar region. *Science* 330. doi:10.1126/science.1187726
- Li, S. et al. (2018) Direct evidence of surface exposed water ice in the lunar polar regions. *PNAS* 115. doi:10.1073/pnas.1802345115
- Haruyama, J. et al. (2008) Lack of exposed ice inside lunar south pole Shackleton Crater. *Science* 322. doi:10.1126/science.1164020
- Zhang, S. et al. (2020) First measurements of the radiation dose on the lunar surface. *Science Advances* 6. doi:10.1126/sciadv.aaz1334
- Qiu, Jian, Zhang & Xie (2021) Plant gravitropism and signal conversion under a stress environment of altered gravity. *Int. J. Mol. Sci.* 22, 11723. doi:10.3390/ijms222111723
- Watters, T.R. et al. (2019) Shallow seismic activity and young thrust faults on the Moon. *Nature Geoscience*. doi:10.1038/s41561-019-0362-2
- Ewert, M.K., Chen, T.T. & Powell, C.D. (2022) Life Support Baseline Values and Assumptions Document, NASA/TP-2015-218570/REV2
- Pappa, R. et al. (2021) Relocatable 10 kW Solar Array for Lunar South Pole Missions, NASA/TM-20210011743
- Clowdsley, M. (2021) Protecting Astronauts from Space Radiation on the Lunar Surface, NTRS 20210009760
- Suggs, R.M. et al. (2014) lunar impact flux, summarised in NTRS 20150016513; Moser, D.E., Suggs, R.M. & Ehlert, S.R. (2017), NTRS 20170004471
- Bryant, S. (2009) Lunar Pole Illumination and Communications Maps, IPN Progress Report 42-176

The other science and learning-research sources (Speyerer & Robinson 2013, Gläser et al. 2014, Watters et al. 2024, Hagedorn et al. 2024, Partap & Ya 2012, Poulet et al. 2014, Wouters et al. 2013, Aronson & Bridgeman 1979, Crookall, the GLE 72 study and the news and NASA pages for each fact) are listed with links in [docs/SCIENCE_AND_DATA.md](docs/SCIENCE_AND_DATA.md) (Sources) and [docs/research/similar-games-and-nasa-data.md](docs/research/similar-games-and-nasa-data.md).

## 8. Pitch video (`LastLightAcademy_pitch_video.mp4`)

- Solar-flare footage: NASA Goddard / SDO, "The X8.2 Flare of September 2017, as Seen by SDO" — <https://svs.gsfc.nasa.gov/4491>
- Character animations: Adobe Mixamo
- Narrator and character voices: ElevenLabs (text-to-speech from our script)
- 3D character models: Tripo AI
- Blender scene and animation scripts, motion graphics, synthesized music and sound effects, edit and subtitles: Claude Code (Anthropic), directed by the team
- Font: Baloo Da 2 (SIL OFL 1.1)
- Rendering: Blender

Twenty models first made for the video are reused in the game; they are listed in §5.

## 9. In-game credits screen

The credits screen (owned by the UI/release tasks, see [execution/RELEASE_02_CREDITS_AND_EVIDENCE.md](execution/RELEASE_02_CREDITS_AND_EVIDENCE.md)) shows only what ships in that build, in English, in this order:

1. **Team The Last BrainCell** — names and roles from `docs/TEAM.md`.
2. **Story, characters, puzzles and science mapping** — the team.
3. **Data** — "Built on NASA open data": the NASA rows of §6 by dataset name and agency, then "with data from NOAA, USGS/IAU, ESA, ISRO, JAXA, CNSA and the Wisconsin Fast Plants Program". Each in-game Data Card already carries its own source and URL.
4. **Made with AI tools** — Tripo AI, Meshy, ElevenLabs, Google Nano Banana Pro, ByteDance Seedance 2.5, OpenAI GPT Image 2.5, Topaz Image Upscale, Claude Code, OpenAI Codex; "every generation is logged with its prompt; see docs/AI_USE.md".
5. **Engine** — "Made with Godot Engine" plus the full Godot MIT licence text and third-party notices, read at runtime from `Engine.get_license_text()` and `Engine.get_copyright_info()` (this is how the MIT notice and the Open Sans OFL notice ship with the build).
6. **Tools** — Blender, FFmpeg.
7. **Disclaimer** — "Aurora Station, the cadets and Alo are fiction. The 2017 storm is a historical replay; the 2012 storm is a what-if. NASA does not endorse this game."

## 10. Open items before submission

- **Team roster:** create `docs/TEAM.md` with every member and role; the in-game credits read from it.
- **AI service terms:** the repository does not record which plan each AI account is on. Before the repo is made public, the team confirms that each service's terms let us publish its outputs in a public, open-source repository (Tripo, Meshy, ElevenLabs, Google, OpenAI, Topaz, ByteDance Seedance via ElevenLabs). Free tiers of some services license outputs differently from paid tiers.
- **Unrecorded tools:** the AI tools behind two work items are not recorded (see [docs/AI_USE.md](docs/AI_USE.md), "AI agents whose tool is not recorded"); confirm them.
- **New assets:** every file added to `game/assets` later needs a row in §5 and in the AI prompt log.
