# Video 2: the 240-second local judging video

Team **The Last BrainCell** · Dhaka, Bangladesh · Challenge: **Build a Junior Astronaut Mission Trainer** · Project: **Last Light Academy**

Board M2-03 (script, shot list, subtitles), written 7 November 2026. Next: M2-04 records the captures and the narration from the frozen 12 November build, M2-05 edits with burned-in English subtitles, M2-06 uploads by 13 November 18:30.

- **Runtime:** narration ends at 3:55.0; end card 3:55.0–3:58.0; **final cut 3:58 at most**. Anything past 4:00 is cut off by the judges.
- **Subtitles:** [V2_subtitles.srt](V2_subtitles.srt) is the draft, 52 cues, timed to this beat sheet. After the narration is recorded, re-time each cue to the voice (keep the cue text) and burn it in.
- **Voice:** 483 narrated words over 200.8 s of speech (2.4 words a second), leaving the game's own sound room in the demo.

## Rules, and where this video meets each

| Rule (competition-rules.md §B, §E, §H) | Where |
|---|---|
| Under 240 s | 3:58 cut; the timings below add up to it |
| Team name | Title card at 0:13 and narration at 3:34.8 |
| Every member named | Narration 3:38.6–3:48.6 plus the team card, all six as registered (docs/TEAM.md) |
| Problem and challenge statement | 0:15–0:40, with the exact challenge text on screen at 0:30–0:40 |
| The solution, with a demo of it working | 0:40–2:50: real gameplay captures of P-02 planning, the CS-02 cutscene, the storm alarm, a Data Card and the outcome |
| NASA data said out loud | 2:22–2:33 (GOES-13 and DONKI) and 2:50–3:25 (BVAD, NASA LaRC array, NASA shielding, LRO LOLA, JPL Horizons) |
| Generated content credited | Per-shot AI chips (Veo, Seedance, ElevenLabs) plus the AI credits card at 3:48.8–3:55, and the spoken line at 3:48.8 |
| English subtitles | V2_subtitles.srt, burned in |
| No names, voices or faces of anyone under 18 | No team member is under 18 (docs/TEAM.md, 7 Nov); the cast are adults; the narrator is an adult or an adult AI voice |
| No NASA logos, no implied endorsement | None in the game; end card says "Not endorsed by NASA" |

## Narrator (Sadman decides)

- **Recommended: Shahariar Rahman Shanto**, the team's registered presenter (adult). Record in a quiet room, phone close, one take per section; M2-05 re-times the subtitles to the take.
- **AI option: ElevenLabs "KJ- Signature Tone"** (voice id `mYOHchvvGACyCjnoG363`, eleven_v4, from [voice_cast.csv](../audio/voice_cast.csv)). It is Rao's voice in the game, a calm, warm adult man, and Rao has no lines in Chapter 1, so it clashes with no character in these captures. If used, add "Narration: ElevenLabs AI voice" to the credits card and log the generation in production/AI_PROMPT_LOG.md.

## Beat sheet

Times are mm:ss. "C" numbers are the captures listed further down; "N" numbers are the narration cues (= the .srt cue numbers).

### Hook (0:00–0:15)

| Time | Picture | Narration | On screen | Sound |
|---|---|---|---|---|
| 0:00–0:06 | **C02** CS-01 opening: the Earth mustard field in the wind | N1–N2: "In 2019, a cotton seed sprouted on the Moon. Then the lunar night came, and it did not survive." | Chip, bottom left: "Shot: Google Veo 3.1 (AI) from our start frame". Small source chip at 0:01: "CNSA Chang'e-4, 2019" | Field wind and birds from the film, under the voice |
| 0:06–0:09 | **C02** the hard cut to the silent Moon exterior | (silence) | none | Silence: the cut to vacuum is the point |
| 0:09–0:15 | **C04** Alo in her chamber in the garden (true leaf or bud stage) | N3–N4: "This is Alo. Can your crew keep her alive through one Moon night?" | Title at 0:13: **LAST LIGHT ACADEMY** · "Team The Last BrainCell · Dhaka, Bangladesh" | Music: the CS-01 title sting |

### Problem and challenge (0:15–0:40)

| Time | Picture | Narration | On screen | Sound |
|---|---|---|---|---|
| 0:15–0:25 | **C05** EX-CH01-S06 night timeline at the Mission Table, then **C03** the four Outpost Status cards | N5–N6: "Real missions are trade-offs. The power that warms the crew also makes their air. The water that shields them from a storm is the water the plants drink." | Two captions as each idea lands: "power → heat or air", "water → shield or plants" | Low music bed |
| 0:25–0:30 | **C03** the crew in the Commons around the Mission Table | N7: "Most space lessons skip that, or make it too hard to follow." | none | |
| 0:30–0:40 | Still frame of the commons, dimmed, under a full-screen text card | N8–N10: "Our challenge: Build a Junior Astronaut Mission Trainer, where students run a Moon outpost, and feel which choices make a mission succeed or fail." | The exact challenge text: *"Your challenge is to design and build an interactive game or app that lets students run a lunar or Martian outpost, balancing competing demands like life support, radiation shielding, power, and food production, so they experience firsthand the decisions that determine whether a mission fails or succeeds."* · NASA Space Apps Challenge 2026 | |

### Solution and live demo (0:40–2:50)

| Time | Picture | Narration | On screen | Sound |
|---|---|---|---|---|
| 0:40–0:52 | **C01** title screen → New Expedition → Enter Aurora, then **C03** walking into the Commons (EX-CH01-S01) | N11–N13: "This is Last Light Academy. You and three friends run Aurora Station, at the Moon's south pole. The Sun is about to set for thirty-six hours." | Lower third: "Live gameplay · Godot 4.7 · Windows and macOS" | Game audio low: fans, footsteps |
| 0:52–1:00 | **C03** close on the four Outpost Status cards | N14–N15: "Four cards stay on screen: life support, radiation shielding, power and food. Everything you do moves them." | Highlight each card as it is named | |
| 1:00–1:16 | **C06** EX-CH01-S07: the four role cards, then the Mission Table opens on shift 1 | N16–N18: "At the Mission Table, you plan every shift of the night. Kai knows the battery, Amara the air, Mei the garden, Rafi the space weather. Nobody sees everything." | Role colours as each name is said | |
| 1:16–1:23 | **C06** Air maker **High**, Garden light **Full**, press **Try it**: the forecast bars move (Battery 14 → 15, Air 6 → 7) | N19: "Press Try it, and the forecast shows what will happen before anything changes." | none: let the real bars move | UI clicks |
| 1:23–1:33 | **C06** scroll to Kai's crew note, then **Lock in shift** and the confirmation | N20–N21: "Making air now uses sunlight that a full battery would waste. Lock it in, and the station lives with your choice." | | |
| 1:33–1:52 | **C07** CS-02 *The Horizon Closes One Door* (EX-CH01-S09): last light, the masts stop, the Earth link greys out | N22–N24: "Then the last light goes, and the solar masts stop. In this training scenario, the link to Earth is cut. No help from Mission Control." Then 10 s of the film's own sound and captions | Chip: "Cutscene: Seedance 2.5 shots (AI) from our frames · voices ElevenLabs (AI)" | The film's audio up after 1:42.4 |
| 1:52–2:09 | **C08** EX-CH01-S10: the four cadets sheltered, the alarm, the Mission Table showing PUMP / STACK / WAIT with their forecasts | N25–N28: "Shift five. Rafi's radiation counter jumps. A solar storm: a replay of the real one from 10 September 2017. Seventy minutes of warning. Pump water into the shelter wall, stack supplies, or wait?" | Source chip: "Storm timing: NASA DONKI, 10 Sep 2017" | Alarm sound from the game |
| 2:09–2:22 | **C08** STACK chosen: the supply bundles snapped into the bunk slots; the forecast shows the dose and Alo's water | N29–N30: "Every choice costs something. Water in the wall protects the crew, but it is the same water Alo's roots need." | | |
| 2:22–2:37 | **C09** the storm Data Card (GOES-13 chart, "Observed"), then 4 s of the explainer **F2** `sci_proton_flux_chart` at "seventy minutes" | N31–N34: "Every number has a Data Card. This storm curve was measured by NOAA's GOES-13 satellite, with flare times from NASA's DONKI records. Each value is labelled: observed, computed, or a training assumption." | none: the card's own labels show | |
| 2:37–2:50 | **C10** EX-CH01-S11 outcome (Bloom or Golden Bloom), the decision replay stepping through shifts 5 and 6, then **C11** CS-03 the shutter opens on Alo's first flower (EX-CH01-S12) | N35–N37: "At sunrise you see what you chose, what the forecast said, and what really happened. Keep the crew safe and Alo alive, and at first light she blooms." | | CS-03 music swells under the last line |

### NASA data (2:50–3:25)

| Time | Picture | Narration | On screen (source chip, top left) |
|---|---|---|---|
| 2:50–2:59 | **F7** fast montage of four Data Cards / Journal sources (C09 alternates) | N38–N39: "NASA data sits at the core of the game. Twenty-nine NASA and partner sources ship inside it, and it works offline." | "29 sources · 21 NASA · 8 partner (NOAA, USGS/IAU, ESA, ISRO, JAXA, CNSA, UW–Madison)" |
| 2:59–3:05 | **F3** explainer `sci_crew_needs` | N40–N41: "Air comes from NASA's life support baseline: 0.895 kilograms of oxygen per person per day." | "NASA BVAD Rev 2 (2022)" |
| 3:05–3:10 | **F4** explainer `sci_solar_power` | N42: "Power, from NASA Langley's ten-kilowatt solar array for the south pole." | "NASA LaRC, NASA/TM-20210011743" |
| 3:10–3:16 | **F5** explainer `sci_shielding`, or **C08**'s water-wall gauge | N43: "Shielding: about twenty centimetres of water, from NASA radiation studies." | "20 g/cm² of water · NASA LaRC (Townsend 1988; Clowdsley 2021)" |
| 3:16–3:25 | **F6** LOLA terrain stills (Aurora ridge vista, Malapert summit) then explainer `sci_earth_position` | N44–N45: "The ground is real LRO LOLA elevation data, and the Sun and Earth move as JPL Horizons computes them." | "LRO LOLA · NASA GSFC PGDA · JPL Horizons" |

### Impact and team (3:25–3:55), end card (3:55–3:58)

| Time | Picture | Narration | On screen |
|---|---|---|---|
| 3:25–3:31 | **C03** the commons at 150 % text with captions on (Settings → Large text) | N46: "It's free, open source, and runs offline on Windows and Mac." | "Apache-2.0 · captions on · nothing timed by default · text 1.5× · reduced motion". Optional lower third: "Playtest: [metric from M1-22 when the playtest runs]" (delete if M1-22 has not run) |
| 3:31–3:35 | **C12** the four role cards side by side (or the Class mode screen if M1-37 is in the build) | N47: "Next: a four-player class mode, with private clues for every role." | |
| 3:35–3:49 | **F8** the five fitted EVA suits (M3-3A lineup, caption bar cropped), then the team card | N48–N50: "We are Team The Last BrainCell, from Dhaka, Bangladesh: Nafis Mohtasim Ramim, Khandaker Shadman Sakib Siddiquee, Md. Asif Iqbal, Abu Sayem Mohammed Tanvir, Shahariar Rahman Shanto and MD Atik Khan." | Team card, each name with role: Nafis Mohtasim Ramim (team leader; UI/UX and player systems) · Khandaker Shadman Sakib Siddiquee (producer, art and media lead, integrator) · Md. Asif Iqbal (science and accessibility review) · Abu Sayem Mohammed Tanvir (QA and playtest lead) · Shahariar Rahman Shanto (presenter) · MD Atik Khan (gameplay runtime, Moon systems and builds) |
| 3:49–3:55 | **C11** Alo's flower, held | N51–N52: "AI-made assets are credited on screen. One night. Four friends. The first flower on the Moon." | AI credits card: "Made with AI tools, every generation logged in our repository: Claude Code (Anthropic) · OpenAI Codex · Google Antigravity · Nano Banana Pro (Gemini 3 Pro Image) · GPT Image 2.5 · Topaz · Tripo AI · Meshy · ElevenLabs (voices, music, effects) · Seedance 2.5 · Google Veo 3.1. Story, dialogue, puzzles, science mapping and art direction by the team." |
| 3:55–3:58 | Black | (none) | **Last Light Academy** · github.com/SadManQT/nasa-space-apps-2026 · "NASA data: DONKI, BVAD, LRO LOLA, LRO CRaTER, JPL Horizons and more, credited in the game" · "An independent team project, not endorsed by NASA" |

**Alternative line if Class mode ships.** If board M1-37 is `done` and the frozen build has Class mode, replace N47 with "Up to four players share one screen, each with private clues." (same length, same timing) and use the real Class mode screen in C12. Otherwise keep N47 as written: it says "next", which is true.

## Narration (= V2_subtitles.srt)

In and out times are mm:ss,ms. The text is the .srt text; numbers in the voice: "0.895" is read "zero point eight nine five", "10 September 2017" is read "the tenth of September, 2017", "GOES-13" is read "goes thirteen", "LRO LOLA" is read "L-R-O LOLA".

| # | In | Out | Section | Narration |
|---|---|---|---|---|
| 1 | 00:00,300 | 00:03,400 | Hook | In 2019, a cotton seed sprouted on the Moon. |
| 2 | 00:03,600 | 00:07,200 | Hook | Then the lunar night came, and it did not survive. |
| 3 | 00:09,000 | 00:10,200 | Hook | This is Alo. |
| 4 | 00:10,400 | 00:14,600 | Hook | Can your crew keep her alive through one Moon night? |
| 5 | 00:15,200 | 00:20,300 | Problem and challenge | Real missions are trade-offs. The power that warms the crew also makes their air. |
| 6 | 00:20,500 | 00:25,400 | Problem and challenge | The water that shields them from a storm is the water the plants drink. |
| 7 | 00:25,600 | 00:29,800 | Problem and challenge | Most space lessons skip that, or make it too hard to follow. |
| 8 | 00:30,000 | 00:33,700 | Problem and challenge | Our challenge: Build a Junior Astronaut Mission Trainer, |
| 9 | 00:33,900 | 00:36,400 | Problem and challenge | where students run a Moon outpost, |
| 10 | 00:36,500 | 00:39,800 | Problem and challenge | and feel which choices make a mission succeed or fail. |
| 11 | 00:40,400 | 00:42,600 | Solution and live demo | This is Last Light Academy. |
| 12 | 00:42,800 | 00:47,400 | Solution and live demo | You and three friends run Aurora Station, at the Moon's south pole. |
| 13 | 00:47,800 | 00:51,600 | Solution and live demo | The Sun is about to set for thirty-six hours. |
| 14 | 00:52,200 | 00:56,400 | Solution and live demo | Four cards stay on screen: life support, radiation shielding, power and food. |
| 15 | 00:56,600 | 00:59,600 | Solution and live demo | Everything you do moves them. |
| 16 | 01:02,000 | 01:06,200 | Solution and live demo | At the Mission Table, you plan every shift of the night. |
| 17 | 01:06,400 | 01:12,200 | Solution and live demo | Kai knows the battery, Amara the air, Mei the garden, Rafi the space weather. |
| 18 | 01:12,400 | 01:14,800 | Solution and live demo | Nobody sees everything. |
| 19 | 01:16,000 | 01:21,600 | Solution and live demo | Press Try it, and the forecast shows what will happen before anything changes. |
| 20 | 01:23,000 | 01:28,400 | Solution and live demo | Making air now uses sunlight that a full battery would waste. |
| 21 | 01:28,600 | 01:32,600 | Solution and live demo | Lock it in, and the station lives with your choice. |
| 22 | 01:33,000 | 01:36,600 | Solution and live demo | Then the last light goes, and the solar masts stop. |
| 23 | 01:36,800 | 01:39,900 | Solution and live demo | In this training scenario, the link to Earth is cut. |
| 24 | 01:40,000 | 01:42,400 | Solution and live demo | No help from Mission Control. |
| 25 | 01:52,400 | 01:56,400 | Solution and live demo | Shift five. Rafi's radiation counter jumps. |
| 26 | 01:56,600 | 02:01,800 | Solution and live demo | A solar storm: a replay of the real one from 10 September 2017. |
| 27 | 02:02,000 | 02:04,200 | Solution and live demo | Seventy minutes of warning. |
| 28 | 02:04,300 | 02:07,600 | Solution and live demo | Pump water into the shelter wall, stack supplies, or wait? |
| 29 | 02:09,000 | 02:14,200 | Solution and live demo | Every choice costs something. Water in the wall protects the crew, |
| 30 | 02:14,400 | 02:18,600 | Solution and live demo | but it is the same water Alo's roots need. |
| 31 | 02:22,400 | 02:26,400 | Solution and live demo | Every number has a Data Card. |
| 32 | 02:26,600 | 02:29,700 | Solution and live demo | This storm curve was measured by NOAA's GOES-13 satellite, |
| 33 | 02:29,800 | 02:32,600 | Solution and live demo | with flare times from NASA's DONKI records. |
| 34 | 02:32,800 | 02:36,800 | Solution and live demo | Each value is labelled: observed, computed, or a training assumption. |
| 35 | 02:37,600 | 02:40,200 | Solution and live demo | At sunrise you see what you chose, |
| 36 | 02:40,300 | 02:43,200 | Solution and live demo | what the forecast said, and what really happened. |
| 37 | 02:43,600 | 02:48,800 | Solution and live demo | Keep the crew safe and Alo alive, and at first light she blooms. |
| 38 | 02:50,200 | 02:54,200 | NASA data | NASA data sits at the core of the game. |
| 39 | 02:54,400 | 02:58,800 | NASA data | Twenty-nine NASA and partner sources ship inside it, and it works offline. |
| 40 | 02:59,000 | 03:01,800 | NASA data | Air comes from NASA's life support baseline: |
| 41 | 03:01,900 | 03:05,400 | NASA data | 0.895 kilograms of oxygen per person per day. |
| 42 | 03:05,600 | 03:10,400 | NASA data | Power, from NASA Langley's ten-kilowatt solar array for the south pole. |
| 43 | 03:10,600 | 03:16,000 | NASA data | Shielding: about twenty centimetres of water, from NASA radiation studies. |
| 44 | 03:16,200 | 03:20,200 | NASA data | The ground is real LRO LOLA elevation data, |
| 45 | 03:20,300 | 03:24,600 | NASA data | and the Sun and Earth move as JPL Horizons computes them. |
| 46 | 03:25,000 | 03:30,600 | Impact and team | It's free, open source, and runs offline on Windows and Mac. |
| 47 | 03:30,800 | 03:34,600 | Impact and team | Next: a four-player class mode, with private clues for every role. |
| 48 | 03:34,800 | 03:38,400 | Impact and team | We are Team The Last BrainCell, from Dhaka, Bangladesh: |
| 49 | 03:38,600 | 03:43,400 | Impact and team | Nafis Mohtasim Ramim, Khandaker Shadman Sakib Siddiquee, Md. Asif Iqbal, |
| 50 | 03:43,600 | 03:48,600 | Impact and team | Abu Sayem Mohammed Tanvir, Shahariar Rahman Shanto and MD Atik Khan. |
| 51 | 03:48,800 | 03:51,000 | Impact and team | AI-made assets are credited on screen. |
| 52 | 03:51,200 | 03:55,000 | Impact and team | One night. Four friends. The first flower on the Moon. |

**Where each spoken fact comes from** (judges check claims): cotton seed 2019 — `change4_cotton` (Chang'e-4, CNSA); 36-hour night — `lro_mazarico_2011_illumination` (about 1.5 days of darkness at a Shackleton-rim site → 5 × 7.2 h), a training scenario; Earth link cut — an authored training event (`jpl_horizons_ch1_sky`: Earth is below the pole's horizon all night); 10 September 2017 and seventy minutes — `donki_2017_09` (X8.2 flare 15:35 UT, >10 MeV onset 16:45 UT); GOES-13 storm curve — `goes13_protons_2017_09`; twenty-nine sources — the 29 fixtures in `game/resources/data/nasa/`; 0.895 kg — `bvad_2022_metabolic`; ten-kilowatt array — `vsat_relocatable_array`; twenty centimetres of water — `clowdsley_2021_shielding` (6 wall units = 20 g/cm² of water; Townsend et al. 1988); LOLA terrain and Horizons — `lro_lola_south_pole_terrain`, `jpl_horizons_*`. Shift-1 forecast numbers (Battery 14 → 15, Air 6 → 7) are what the game shows for High air and Full light (production/qa/evidence/M1-55_shift1_forecast.png).

## Captures needed (for M2-04)

Record from the frozen 12 November build (M1-24 / M3-93) at 1920×1080, 60 fps, OBS, game window only: no notifications, no desktop, no personal names. Settings: captions **on** (default), text 100 % except C03b, reduced motion off. Use a fresh save slot. Play Chapter 1 once from New Expedition and **save at each marked point** (Esc → Save) so a retake starts from the save, not from the title. Record 3–5 s of handles before and after every action. Move the mouse slowly and pause 1 s on every button before clicking.

| Id | Scene | What to do on camera | Length | Used at |
|---|---|---|---|---|
| C01 | Title | Start the build. Hold on the title screen 4 s. Click **New Expedition**, hold 2 s on the mission briefing, click **Enter Aurora**. | 15 s | 0:40 |
| C02 | EX-CH01-S01, CS-01 *Arrival* | Let the film play to the end without skipping: field shot with "[wind and birds]" (0–6 s), hard cut to the silent exterior at 6.0 s, the commons as the fans come up, the title over the gold band. Also export the field shot clean from `game/assets/cutscenes/CS-01_Arrival.ogv` as backup. | 21 s | 0:00 |
| C03 | EX-CH01-S01, Commons | After the film, let the four S01 lines play with captions. Then walk (WASD, look with the mouse) slowly from the spawn to the Mission Table; the crew turn to the speaker. Hold 6 s on the four **Outpost Status** cards. **Save** (save 1). | 40 s | 0:15, 0:25, 0:52 |
| C03b | Any Commons moment | Esc → Settings → **Large text** on (150 %), back to the game, hold 6 s with a caption on screen; then set it back. | 10 s | 3:25 |
| C04 | EX-CH01-S04 / S05, Garden | Stand at Alo's chamber; frame Alo (purple stem) through the glass for 8 s without moving; repeat once more at a later visit if her stage changes. | 16 s | 0:09 |
| C05 | EX-CH01-S06 *The Night Has a Shape* | At the Mission Table do **Arrange the timeline**: place the Sun, link and station tracks; hold 4 s on the finished timeline (36 h of dark, the Earth link marked), then acknowledge the schedule. **Save** (save 2). | 25 s | 0:15 |
| C06 | EX-CH01-S07 *Air Before the Jar Spills* | Read the four role cards one by one (2 s each), acknowledge. Open the Mission Table on **shift 1**. Guide 1: set **Air maker → High**; Guide 2: **Garden light → Full**; Guide 3: press **Try it** and hold 4 s while the bars move (Battery 14 → 15, Air 6 → 7); scroll down to Kai's crew note, hold 3 s; press **Lock in shift (Space)**, confirm. **Save** (save 3). | 50 s | 1:00–1:33 |
| C07 | EX-CH01-S09 *The Horizon Closes One Door* | Combine Mei's and Rafi's cards, acknowledge the Earth-link cutoff; let **CS-02** play in full without skipping. Then commit shifts 3–4 (any safe plan). **Save** (save 4). | 50 s | 1:33 |
| C08 | EX-CH01-S10 *The Choice Inside the Rules* | Confirm all four cadets sheltered (let the four S10 lines play: "Four names. Four answers. Then we commit."). On the alarm table, press **Try it** on **PUMP**, then **STACK**, then **WAIT**, holding 3 s on each forecast. Choose **STACK** and do the placement task: snap the four supply bundles into the outlined bunk slots, slowly. Hold 3 s on the forecast (dose, water in the wall), then commit the alarm response. **Save** (save 5). | 60 s | 1:52–2:22 |
| C09 | The storm Data Card | From the alarm table or **Journal → Sources**, open the Data Card *GOES-13 proton flux during the 10 September 2017 storm*: hold 3 s on the chart and the "Evidence · Observed" label, then scroll slowly through "What was measured" and "What the game computed". Repeat for two more cards (the shielding card from the Outpost Status shielding card; the night-length card) for the NASA-data montage. | 40 s | 2:22, 2:50 |
| C10 | EX-CH01-S11 *Send the Water Home* | Verify exposure before the drain, return the water, commit shifts 6–7 with a plan that keeps Alo alive (Bloom; Golden Bloom if reached). On the outcome screen hold 3 s, open the **decision replay**, step with **Next shift** to shifts 5 and 6 (2 s each), then open the science debrief and hold 3 s. If the outcome is Alo Lost or Mission Stopped, reload save 5 and retry; never stage a fake ending. | 45 s | 2:37 |
| C11 | EX-CH01-S12 *Alo Needs a Friend* | Verify the chamber, open the shutter; let **CS-03** play: the shutter, Alo's first flower and N.'s stored message. | 35 s | 2:43, 3:49 |
| C12 | Role cards / Class mode | If Class mode (M1-37) is in the build: New Expedition → Class (4 players) → show the private role-card hand-off screen. Otherwise reopen the Mission Table role cards and hold 4 s. | 10 s | 3:31 |

**From files, no recording needed** (copy the file, crop nothing unless noted):

| Id | File | Use |
|---|---|---|
| F2 | `game/assets/explainers/science/sci_proton_flux_chart.ogv` (the "seventy minutes" frame is near 0:30) | 2:33–2:37 |
| F3 | `game/assets/explainers/science/sci_crew_needs.ogv` | 2:59 |
| F4 | `game/assets/explainers/science/sci_solar_power.ogv` | 3:05 |
| F5 | `game/assets/explainers/science/sci_shielding.ogv` | 3:10 |
| F6 | `production/qa/evidence/M1-34_aurora_ridge_vista.png`, `M1-34_malapert_summit_vista.png` (crop the three debug lines at the top), then `game/assets/explainers/science/sci_earth_position.ogv` | 3:16 |
| F7 | `production/qa/evidence/M0-15_data_card.png`, `M1-19_nasa_data_card.png`, `M1-28_data_card_status.png` (stills, only if C09 is short) | 2:50 |
| F8 | `production/qa/evidence/M3-3A_eva_front.png` (crop the caption bar at the top) | 3:35 |

Large files are in Git LFS: `git lfs pull --include="game/assets/explainers/science/*.ogv,game/assets/cutscenes/CS-0[1-3]*.ogv,production/qa/evidence/M1-34_*,production/qa/evidence/M3-3A_eva_front.png"`.

## Edit notes (for M2-05)

- Mix: narration at −16 LUFS integrated, game sound ducked 10 dB under the voice, up between cues. Keep the 0:06–0:09 silence.
- Burn in V2_subtitles.srt (white, dark backing box, bottom centre, at least 42 px tall at 1080p). The game's own captions stay on in the captures; place narration subtitles so they never cover a game caption (move them up during C07 and C11).
- Show only real gameplay for the demo. Stills (F6–F8) appear only in the NASA data and team sections and are in-engine renders.
- No NASA logo anywhere, including the end card; say "NASA data", never "NASA's game".
- Export H.264 1080p, check the length is 3:58 or less, and play the export once start to finish with sound before upload.
