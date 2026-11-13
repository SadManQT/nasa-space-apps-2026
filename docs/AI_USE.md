# Use of AI — Last Light Academy

Team The Last BrainCell · NASA Space Apps Challenge 2026 · *Build a Junior Astronaut Mission Trainer*
Updated 5 November 2026 (first written 3 November). This page is the summary the game's **Science + Sources** screen and the [README](../README.md#use-of-ai) point to. The full record of every generation is [production/AI_PROMPT_LOG.md](../production/AI_PROMPT_LOG.md): one row per generation with the tool and model, the exact prompt (or where it is stored), the inputs, the result, and what a person changed or decided. Rejected results stay in the log, marked rejected. Log rows are cited below as *date · asset*, the first two columns of the log, so each can be found with a text search.

## Summary (paste-ready)

We are a team of six building a full 3D Moon-outpost game (8 chapters, 32 missions, 96 scenes), so we used AI where it saves the most time and where we have no specialist. AI tools made the 3D models, concept and turnaround images, character animation clips, all 383 voice lines, the music score (12 cues, 16 files), all 35 sound effects and the 18 cutscenes, and wrote most of the game code and many production documents against our specifications. The story, characters, every line of dialogue, the puzzle rules and numbers, the science mapping, the art direction and every approval or rejection are the team's. AI tools turned our written designs and approved reference images into assets; they are not allowed to change the story text or the puzzle numbers. Every generation is logged with its prompt in [production/AI_PROMPT_LOG.md](../production/AI_PROMPT_LOG.md).

Tools used: **Claude Code** (Anthropic; Claude Opus 5.5, one Sonnet 5.5 task) for pipeline scripts, prompts for the other tools, game code, documents and orchestration; **OpenAI Codex** (GPT-6, gpt-6-astra) for game code and tests, code review, bug hunts, release builds and the lunar rock kit; **Antigravity** (Google, Gemini 4 Argon) for requirements and NASA mission-practice documents; **Google Nano Banana Pro** (Gemini 3 Pro Image) for concept art, turnarounds, portraits and cutscene start frames; **OpenAI GPT Image 2.5 Sunburst** for cutscene start frames and frame edits; **Topaz Image Upscale v2** for 4x upscales; **Tripo AI** for 3D models and skeletons; **Meshy** for animation clips and five story motions; **ElevenLabs** for voices, music and sound effects, and as the Flows workspace that ran the image and video models; **ByteDance Seedance 2.5** for cutscene video shots; **Google Veo 3.1** (in Google Flow) for the one 6-second mustard-field shot that opens CS-01 (M1-52). No NASA dataset was given to a generative model: the NASA data extracts come from a plain Python script ([production/tools/fetch_nasa_data.py](../production/tools/fetch_nasa_data.py)) and values quoted from cited papers ([SCIENCE_AND_DATA.md](SCIENCE_AND_DATA.md)).

## Every tool at a glance

| Tool (maker) | Models recorded in the log | What it made for the game |
|---|---|---|
| Claude Code (Anthropic) | Claude Opus 5.5; Claude Sonnet 5.5 (one task) | Production pipeline scripts; prompts for the image, video, voice, music and effect tools, and running those jobs; cutscene assembly; game code for cutscene playback, the audio runtime and fixes; NASA data fixtures and mission data cards; design and review documents; the README, handbook, team board and this page; overnight "night shift" tasks; the pitch video's scripts, music and edit |
| OpenAI Codex | GPT-6; gpt-6-astra (reasoning xhigh) | Game code and tests (face runtime, toon shaders, data cards, habitat greybox, companions, saved knowledge, outpost status, later-chapter ledgers, story-log save schema), code review, bug hunts and fixes, portable release builds, the lunar rock and regolith kit (Blender scripts), overnight "night shift" tasks |
| Antigravity (Google) | Gemini 4 Argon; Gemini 4 Argon High | Two design documents: requirements alignment and training decisions (M1-27) and real NASA mission practice behind every decision (M1-39) |
| Nano Banana Pro (Google) | gemini-3-pro-image (in ElevenLabs Flows); gemini_3_pro_image_preview (through Tripo) | Style key frames, cast turnaround sheets in every art direction, plant and prop concepts, screen portraits, cutscene start frames and frame edits |
| GPT Image 2.5 Sunburst (OpenAI) | gpt-image-2.5-sunburst | Cutscene start and end frames for CS-13..CS-17 and frame edits (patches, hair, glow) |
| Topaz Image Upscale v2 (Topaz Labs) | CGI model, 4x | Upscales of the chosen turnaround views before 3D generation |
| Tripo AI (VAST) | multiview_to_model / image_to_model v3.1; rigging v1.0 and v3.0 (Mixamo spec, 65 bones) | 3D models of the five characters, the plants and props, and the character skeletons; 22 props and vehicles first made for the pitch video and reused |
| Meshy | auto-rig, preset animation library, text-to-motion (prime), multi-image-to-3d meshy-7.1 (replaced) | Motion-source rigs and animation clips for all five characters and five story motions (Pollinate, Water, Inspect, Type, Repair) |
| ElevenLabs | eleven_v4 (voices); eleven_music_v2_5 (music); Sound Effects v2 | All 386 voice lines, the 12-cue score (16 files), all 38 sound effects; the Flows workspace (and, for Chapters 7–8 voices, the ElevenLabs connector) that ran the image and video models |
| Seedance 2.5 (ByteDance) | bytedance-seedance-v2.5, including Video Extend | The animated shots in cutscenes CS-01 to CS-17, generated from our start frames |

Also in the log but not generative AI: Python, Blender, Godot, ffmpeg, OpenCV and Windows System.Drawing, used by scripts to clean up, measure, compose and lay out results (rows marked "No AI"). One AI model checks results without making anything the player sees: **Whisper** (mlx-whisper, run locally by [production/tools/master_vo.py](../production/tools/master_vo.py)) transcribes each voice take so the take whose words match the script is picked; it is named in the handbook's 4 November status entry rather than in a log row.

## Tools one by one

### Claude Code (Anthropic)

| | |
|---|---|
| Why | One agent that can plan, write scripts and code, and run the asset pipeline end to end, so the team's time goes into design and review. |
| What it did | **Pipeline:** the scripts in `production/tools/` (Blender clean-up, previews, quality gate, character build, cutscene composer, voice-take picker, Godot sync, presentation-media builder). **Generation runs:** wrote the prompts for Nano Banana Pro, GPT Image, Seedance and ElevenLabs from the [art bible](../production/ART_BIBLE.md), the story and the asset lists, ran the jobs, reviewed every take, and assembled the 18 cutscenes. **Game code:** campaign cutscene playback (M1-10), the campaign audio runtime and mixer (M1-11), Chapter 1 judge-facing text including the in-game AI disclosure (M1-42), and bug fixes (M0-02). **NASA data and science:** the NASA-data-first dataset map (M0-13), offline NASA data fixtures (M0-14), plain-language mission data cards (M1-30), the Chapter 1 science review (M1-40) and the science-document corrections (M1-46). **Design documents for the team's review:** puzzle and clue design for all 32 missions (M1-38), the canon drift fix (M1-41), and the narrative revision proposal [24_NARRATIVE_REVISION](../game-design/24_NARRATIVE_REVISION.md). **Project documents:** the rules check, [team board](../production/plan/BOARD.html) and test runner, the production handbook, the README for judges, licence and credits, and this page. |
| Models | Claude Opus 5.5 from 3 November; Claude Sonnet 5.5 for M1-41. The model for the 25–30 October sessions was not recorded. |
| Representative prompts | User to Claude, 3 Nov: "read all the instructions … check if our project … is all good … fix all the bugs … make a plan so every AI of every PC can track …" (log: *2026-11-03 · Rules check, team board, test runner*). Board tasks are run with "Do board task M1-46 — exactly this one task — at senior, AAA production quality." (log: *2026-11-05 · M1-46 science docs corrections (night shift)*). Prompts Claude wrote for other tools are in their rows below. |
| Human edits and checks | Sadman approves every 2D design sheet before 3D credits are spent, approves or rejects each result, and approves every commit. Design proposals Claude drafts (22_PUZZLE_CLUE_DESIGN, 24_NARRATIVE_REVISION, M1-41) are marked "Pending Sadman's review" in the log and change no canon until approved. Claude's code is checked by Codex and the automated test suites. |
| Log rows | *2026-11-03 · Rules check, team board, test runner; Documentation drift fixes; AI-use disclosure; Bug fixes M0-02 completed; NASA-data-first dataset map*; *2026-11-04 · Offline NASA data fixtures; Licence and credits; Puzzle and clue design; NASA data briefings and debriefs; README for judges; M1-41 canon drift fix; M1-40 Chapter 1 science review*; *2026-11-05 · 24_NARRATIVE_REVISION; M1-10; M1-11; M1-42; M1-46*. Claude's earlier pipeline work appears in the tool and "Human changes" columns of the 25–27 Oct rows. |

### OpenAI Codex

| | |
|---|---|
| Why | A second, independent model for code: it writes runtime code, reviews code it did not write and hunts bugs, so no AI's code goes unchecked. |
| What it did | 26–27 Oct: face expression and head-accent runtime, toon shaders, face atlas, hair springs, the hold layer and a readiness audit. 3 Nov: a read-only bug hunt and the fixes. 4 Nov (Atik's and Tanvir's sessions): the data-card runtime, retiring the dead commissioning slice, the visible habitat greybox, portable export builds and QA, Outpost Status and forecasts, local companions, saved knowledge and evidence, the later-chapter numeric audit and ledgers, the exterior art-direction comparison, and the lunar rock and regolith kit (16 rock forms built by Blender scripts, no image or 3D generation). 5 Nov night shift: NASA fixture corrections (M1-44), story-log save schema 3 (M1-47) and a loading-deadlock investigation (M1-53). |
| Models | GPT-6; gpt-6-astra with reasoning xhigh. |
| Representative prompt | "Review these Godot 4.7 GDScript and shader changes … for real bugs only (crashes, wrong behaviour, edge cases, ordering problems)." (log: *2026-10-27 · v7 runtime code*). |
| Human edits and checks | Claude reviews Codex diffs and reruns all test suites (`game/tools/run_tests.sh`); the teammate who ran the session approves the commit. Tanvir chose the exterior art direction himself (log: *2026-11-04 · M1-33 art decision*). |
| Log rows | *2026-10-26 · Character v4 Godot face runtime and tests*; *2026-10-27 · v7 runtime code*; *2026-11-03 · Bug hunt of game/; Bug fixes B01–B05, B09–B12, B17–B20*; *2026-11-04 · M0-15, M0-03, M1-01, M1-20, M1-28, M1-17, M1-26, M3-80 (two rows), M1-32, M1-33, M1-35 (two rows)*; *2026-11-05 · M1-44, M1-47, M1-53 (night shift)*. |

### Antigravity (Google, Gemini 4 Argon)

| | |
|---|---|
| Why | Research-heavy documents and, by the team's split of work, UI and browser testing. |
| What it did | REQUIREMENTS_ALIGNMENT.md and 19_TRAINING_DECISIONS.md (M1-27; the latter was later reduced to a pointer by M1-41 because it had drifted from canon), and the document on real NASA mission practice behind every decision: trade studies, flight rules, Go/No-Go, checklists, consumables, radiation limits, risk matrices and light-time (M1-39). The handbook's 4 November status entry also credits Antigravity, with Claude, for the second 60 fps performance round; that work has no log row of its own. The interactive puzzle panels P-01 and P-02 (board M1-08, M1-09) are in progress with Antigravity and will be logged when done. On 25 Oct it was tried once as a second reviewer of asset contact sheets; all five of its FIX calls were wrong, so it is not used for visual asset review (visual_review.md). |
| Human edits and checks | Its proposals were collected for the team's approval; canon text and puzzle numbers were not changed. |
| Log rows | *2026-11-04 · Requirements alignment & training decisions for all 32 missions (board task M1-27)*; *2026-11-04 · Real NASA mission practice behind every decision (board task M1-39)*. |

Gemini models appear only as Nano Banana Pro (Gemini 3 Pro Image, below) and inside Antigravity. No Gemini chat or Gemini CLI work is recorded.

### Google Nano Banana Pro (Gemini 3 Pro Image), in ElevenLabs Flows and through Tripo

| | |
|---|---|
| Why | Fast concept art and consistent four-view turnaround sheets, which the 3D tools need as input; screen portraits; start frames for cutscene shots. |
| What it did | Style key frames (25 Oct); cast turnarounds through four art directions (stylised-realistic, v6 realistic, the v7 anime style and its v8 fixes); plant and prop concepts; screen portraits (Rao, Noor 2034, Noor today); start frames and frame edits for every cutscene CS-01 to CS-18 (CS-18 is a single still frame). |
| Representative prompts | "Edit this image. Keep the same composition... Remove the eyes completely from the plant... no eyes, no face, no mouth..." (log: *2026-10-25 · STYLE-03 Alo key frame, no eyes*); "Anime cel-shaded game cutscene still in exactly the drawing style of the reference image ... Wide establishing shot of Aurora, a small lunar research base near the Moon's south pole ..." (log: *2026-10-27 · Cutscenes v7 start frames: CS-01-A/B/C*). |
| Data it worked on | Our text prompts, written from the art bible (black sky, no haze, hard shadows; plants never have faces; no NASA logos; no readable text) and our own approved images as references. |
| Human edits and checks | One take picked or all rejected per prompt (for example a plant with eyes was rejected, and flags were moved to the left shoulder); frames checked against the art bible before any video. |
| Log rows | *2026-10-25 · STYLE-01..03, TURN-KAI..TURN-FER, Plant and prop concepts, Glovebox, crew seat, pollination kit concepts, Noor present-day portrait, CS-01 to CS-03 start frames*; *2026-10-26 · 8 prop concepts, CS-04 to CS-17 start frames, Redo round 2, Audit fixes*; *2026-10-27 · v6 to v8 turnarounds and portraits, Cutscenes v7 start frames*; *2026-11-04 and 2026-11-05 · CS-xx start frames and edits* (one row per frame). |

### OpenAI GPT Image 2.5 Sunburst (in ElevenLabs Flows)

| | |
|---|---|
| What it did | Frame edits in the 26 Oct redo and audit rounds; on 4–5 Nov, start and end frames for CS-13-B, CS-14-B, CS-16-B, CS-17-B, CS-17-C and CS-17-D, the CS-03-C end frame, and patch fixes on CS-14-A and CS-13-B. |
| Human edits and checks | The same frame review as Nano Banana Pro; rejected takes are logged (for example a five-petal patch and blue eyes on Mei). |
| Log rows | *2026-10-26 · Redo round 2; Audit fixes*; *2026-11-04 · CS-14-A edit 2, CS-14-A patch fix*; *2026-11-05 · CS-03-C end frame, CS-13-B, CS-14-B, CS-16-B, CS-17-B, CS-17-C, CS-17-D frame rows*. |

### Topaz Image Upscale v2 (in ElevenLabs Flows)

4x upscales (CGI model, face enhancement off) of the chosen turnaround views before 3D generation. No prompt. Log: *2026-10-27 · v7 anime turnarounds*; *2026-10-27 · v8 side views*.

### Tripo AI

| | |
|---|---|
| Why | Turns an approved four-view sheet or one concept image into a textured 3D model, and auto-rigs characters, in minutes instead of days of modelling. |
| What it did | All five characters (several rounds; the installed cast is the v8 build), the plant and prop models, the skeletons (Mixamo spec, 65 bones with fingers), and 22 props and vehicles first made for the 7 October pitch video and reused in the game. |
| Prompts | None: image-to-3D from our approved images. Settings, task ids and credits are in each row. |
| Human edits and checks | Mei's first v8 model was rejected (her left arm was built twice) and rebuilt; every model passes the automated asset gate and a visual review (asset_verification.md, visual_review.md). Clean-up is scripted in Blender. |
| Log rows | *2026-10-25 · CH-KAI 3D model and rig, CH-AMA..CH-FER 3D models + rigs, 15 props and plants, 22 reused props, PR_PollinationKit 3D model*; *2026-10-26 · 3D models of the 8 props above, v3 finger rigs*; *2026-10-27 · v7 and v8 character models and skeletons, v8 Mei 3D model, retakes*. The original pitch-video prompts for the reused models were not recorded. |

### Meshy

| | |
|---|---|
| What it did | Motion-source rigs and preset clips for all five characters (retargeted onto the Tripo skeletons) and five text-to-motion story actions (Pollinate, Water, Inspect, Type, Repair). A 26 Oct Meshy model rebuild was later replaced and is not in the game. |
| Representative prompt | "A person stands at a waist-high plant tray, leans in slightly and gently dabs the centre of a small flower with a fine brush held in the right hand, careful and precise, then straightens up." (log: *2026-10-26 · Story motions for all five characters*). |
| Human edits and checks | After Sadman reviewed the demo (shrugged shoulders, hip-forward stance, flapping arms) the retargeting was corrected; the Inspect motion was trimmed. |
| Log rows | *2026-10-26 · Character rigs and animation, Story motions, Character rebuild v3 models, v3 motion source rigs and clips*; *2026-10-27 · v7 motion-source rigs and clips, Inspect v3 story motion*. |

### ElevenLabs (voices, music, sound effects, and the Flows workspace)

| | |
|---|---|
| Why | Adult character voices, an original score and effects without a recording studio. Flows is also where Nano Banana Pro, GPT Image, Topaz and Seedance were run. |
| Voices | All **383** spoken lines in `game/assets/audio/voice/`, eleven_v4, nine speakers with the voices listed in [voice_cast.csv](../production/audio/voice_cast.csv). The words are the canon story text, word for word from [STORY_FULL.md](../full-game-story/STORY_FULL.md), with inline delivery tags such as "[warm, gentle, a recorded message from long ago]". Usually two takes per line; the take whose transcript matches the script is kept. |
| Music | The **12-cue** score CUE-01..CUE-12 in **16 files** in `game/assets/audio/music/` (stings, stems and a credits version), plus a cue per cutscene, all eleven_music_v2_5, instrumental. |
| Sound effects | All **35** effects in `game/assets/audio/sfx/`, Sound Effects v2, written to the Moon rules: no sound through vacuum, so outside the habitat only suit-borne sound. |
| Human edits and checks | The words are never changed; takes are picked by transcript match and listed for listening in vo_review.md; music is trimmed, faded and ducked under speech; rejected effect takes are logged. |
| Log rows | Voices: *2026-10-26 · Lip-sync test lines*; *2026-10-27 · Cutscene v7 voice lines*; *2026-11-04 · M1-12 voice cast samples; 12 CH01 lines reused; VO CH01-CH02; VO EX-CH03; VO EX-CH04; VO CH05-CH06; VO CH07-CH08*. Music: *2026-10-27 · Cutscene v7 music*; *2026-11-04 · MUS_CUE-01..MUS_CUE-12 rows and CS-xx music rows*; *2026-11-05 · CS-xx music takes*. Effects: *2026-11-04 · SFX_* rows (one per effect, including rejected takes)*. |

### ByteDance Seedance 2.5 (in ElevenLabs Flows)

| | |
|---|---|
| Why | Short animated shots for the cutscenes, generated from our start frames. |
| What it did | Every animated shot in the 18 cutscenes in `game/assets/cutscenes/`: CS-01 to CS-17 are cut together from 5–11 second Seedance shots (some lengthened with Video Extend); CS-18 is a single still frame. The three shots that were refused for lack of credits on 27 Oct (CS-02-C, CS-03-B, CS-03-C) were generated later (board M1-25), so no cutscene relies on a stand-in push-in any more. The earlier realistic-style shots of 25–26 Oct are archived and not in the game. |
| Representative prompt | "Slow, steady cinematic push-in across the grey lunar ground toward the small base ..." (log: *2026-10-27 · Cutscene v7 video CS-01-A/B/C*). Prompts describe motion only, never dialogue; video is generated without audio. |
| Human edits and checks | Every shot is checked on its start, middle and end frames against the science rules; stars in a sunlit sky and horizon glow are removed in post; dialogue, captions and music are added in our own edit by script (`production/tools/compose_cutscene.py`), not by the video model. Shot plans and reviews: [production/cutscenes/v8/](../production/cutscenes/v8/) notes A–C. |
| Log rows | *2026-10-25 · CS-01-A … CS-03-B videos*; *2026-10-26 · CS-04-A to CS-17-B videos, Redo round 2, Audit fixes*; *2026-10-27 · Cutscene v7 video rows, CS-02-C, CS-03-B, CS-03-C (refused generations)*; *2026-11-04 and 2026-11-05 · CS-xx video rows* (one per shot). |

### Veo

Used once, on 6 November (board M1-52): Veo 3.1 - Quality in Google Flow, frames-to-video from our approved start frame, made the 6-second Earth mustard-field shot that opens CS-01 (take 1 of 2; Veo's own audio dropped). Prompt and checks: [production/ai_log_parts/M1-52.md](../production/ai_log_parts/M1-52.md). Every other cutscene shot is Seedance.

## The night shift

From 5 November some board tasks run unattended overnight: Claude Code (Opus 5.5) and OpenAI Codex (GPT-6) each take exactly one board task, follow the same rules as daytime work (canon text and puzzle numbers untouched; no NASA logos; no purchases; tasks that need a person's approval are blocked, not faked), run the full test suite, and log a row marked "night shift". Nothing is committed by the agent itself; the result is reviewed before a commit is made from Sadman's own GitHub account. Log rows so far: *2026-11-05 · M1-46 (Claude); M1-44, M1-47, M1-53 (Codex)*, plus this page's own update (M2-14).

## AI work whose tool is not recorded

These rows are AI work, but the repository and the commits do not say which tool or model did it. **The team is confirming them** (also noted in the README).

| Work | What it produced | Log row |
|---|---|---|
| Execution prompt library (27 Oct, commit `5f94bc0`) | `execution/`: 300 task prompts, contracts and indexes; documentation only (kept in the team's archive since 13 Nov, not on the main branch) | *2026-10-27 · Execution prompt library* |
| Campaign code, 2–3 Nov | A bootstrap slice, then a supervisor and Workers A, B and C: campaign state and simulation, saves, rooms and missions for Chapters 1–8, the content catalog and accessible UI, with their tests (production/review/execution/) | *2026-11-02 · Bootstrap commissioning slice*; *2026-11-02 to 11-03 · Worker A, Worker B, Worker C*; *2026-11-03 · Supervisor integration* |

## The pitch video (7–10 October)

Claude Code wrote the Blender scene and animation scripts, the motion-graphics animations, the synthesized music and sound effects, and the edit that assembles the film and its subtitles; ElevenLabs made the narrator and character voices from our script; Tripo AI made the 3D character models. Character animations came from Adobe Mixamo; the solar-flare footage is real NASA/SDO footage. These generations predate the log, so their exact prompts are not recorded.

## The 240-second judging video (13 November)

The film is on YouTube; its link is on the project page and in the README. What is ours and what is AI-assisted:

| Part | Who or what made it |
|---|---|
| The story and its points (the problem, the solution, the next steps) | Sadman, for the team |
| The wording of the narration | Claude Code, from Sadman's points; every fact is taken from the sources listed on the film's last card |
| **The narration voices** | **AI-generated.** Each of the six members cloned their own voice in ElevenLabs (instant voice clone, `eleven_v4`), with their consent. Every line is spoken by the clone of the member named on screen, and each member says their own name and role. No member's voice was used for another person's lines. |
| Gameplay footage | Recorded from our own game with Godot's Movie Maker, driven by scripts that Claude Code wrote |
| Cutscenes, science clips and music | The game's own, made as described in the sections above (Seedance, Claude Motion, ElevenLabs music) |
| People on screen | Only the six team members, in their own photos. No person under 18 appears, as the Space Apps terms require |
| How the AI content is marked | Every cutscene shot carries an on-screen "AI-generated image" label. The AI narration and music are named on the film's last card, in the video description and in the file's metadata |
| Motion graphics, captions, the edit and the sound mix | Claude Code, as code (a web page rendered frame by frame, then ffmpeg), kept with the team's video working files. No image or video model was used for the film itself. |

The generation is logged in `production/ai_log_parts/video2_narration_20261113.md`.

**The 30-second demo video** is made the same way: the narration is the presenter's own cloned voice (ElevenLabs), the music is the game's score (ElevenLabs), the closing cutscene shot is labelled "AI-generated image" on screen, and the rest is gameplay recorded from our own game with motion graphics drawn in code. No person under 18 appears.

## Every generated file in `game/assets` and its log rows

| `game/assets/` | Files | Made by | Log rows |
|---|---|---|---|
| `characters/` | CH_Kai, CH_Amara, CH_Mei, CH_Rafi, CH_Ferreira (v8 build) | Nano Banana Pro sheets, Topaz, Tripo models and skeletons, Meshy motion | *2026-10-27 · v7/v8 turnarounds, v8 side views, v8 character 3D models, v8 Mei retakes, v8 final skeletons, v7 motion-source rigs and clips, Inspect v3 story motion*; *2026-10-26 · Story motions*. Face layers and hold poses are drawn by script, no AI (*2026-10-27 · v7 anime face layers*) |
| `plants/`, `props/` | PL_* and PR_* models | Nano Banana Pro concepts, Tripo models; PL_CropRack and 13 props are Tripo models reused from the pitch video | *2026-10-25 · Plant and prop concepts, Glovebox, crew seat, pollination kit concepts, 15 props and plants, 22 reused props, PR_PollinationKit 3D model*; *2026-10-26 · 8 prop concepts, 3D models of the 8 props above* |
| `environment/`, `vehicles/` | EN_CorridorSegment, EN_ExteriorModule, EN_SolarMast, VH_Rover, VH_ReliefLander, VH_ZeroAscent | Tripo, made for the pitch video | *2026-10-25 · 22 reused props* |
| `environment/terrain/` | Lunar rock and regolith kit, scatter code | Blender scripts written by Codex; no image or 3D generation | *2026-11-04 · M1-35 lunar rock/regolith kit and scatter code; M1-35 final surface review* |
| `audio/voice/` | 386 voice lines | ElevenLabs eleven_v4 | See ElevenLabs above |
| `audio/music/` | 16 files, cues CUE-01..12 | ElevenLabs eleven_music_v2_5 | *MUS_CUE-xx* rows |
| `audio/sfx/` | 35 effects | ElevenLabs Sound Effects v2 | *SFX_xx* rows |
| `cutscenes/` | CS-01 to CS-18 (18 films) | Nano Banana Pro and GPT Image frames, Seedance 2.5 shots, ElevenLabs voices and music, assembled by script | See Seedance above; per-cutscene notes in [production/cutscenes/v8/](../production/cutscenes/v8/) |
| `ui/portraits/` | CH_Rao_screen, CH_Noor_present_portrait, CH_Noor_2034_portrait | Nano Banana Pro | *2026-10-27 · v7 screen-only portraits* |
| `ui/portraits/` | CH_Ferreira_screen | A Godot render of the installed model, no image generation | [CH_Ferreira_screen.md](../game/assets/ui/portraits/CH_Ferreira_screen.md) |

## What the team did itself

- **Story and characters.** The story, cast, chapters and every line of dialogue are the team's: the design documents in [docs/](.) were committed by Abu Sayem Mohammed Tanvir on 24 Oct, the game-design pack in [game-design/](../game-design/) by MD Atik Khan and Abu Sayem Mohammed Tanvir on 24 Oct, and the full story edition [STORY_FULL.md](../full-game-story/STORY_FULL.md) on 25 Oct. Every voice line and caption in the game is that text word for word. AI drafts of narrative changes (24_NARRATIVE_REVISION) are proposals that change nothing until Sadman approves them.
- **Puzzle rules and numbers.** All puzzles and every game number come from [08_PUZZLE_DESIGNS.md](../game-design/08_PUZZLE_DESIGNS.md). AI tools implement and test those numbers and are never allowed to change them; where a number raised a question (the P-05 clock), a team member decided (Atik, 4 Nov).
- **Science mapping.** Which NASA observation supports which game moment, and what is observed, computed or invented, is set out in [SCIENCE_AND_DATA.md](SCIENCE_AND_DATA.md) and [16_SCIENTIFIC_ACCURACY.md](../game-design/16_SCIENTIFIC_ACCURACY.md). The science rules every asset must pass (black sky, no fog or wind, lunar gravity, faceless plants inside pressurised enclosures) are the team's, and Sadman approved the Chapter 1 science corrections.
- **Art direction, review and approval.** Sadman directed every style change and the 5 November decision (photoreal environment, cel-shaded cast), approves each 2D design sheet before 3D credits are spent, reviews takes and asks for fixes; Tanvir chose the exterior shading. Rejected AI results are kept in the log as rejected.
- **Code review and integration.** Every commit is made from a team member's own GitHub account, with no AI co-author. AI-written code is cross-checked by a second AI and by the automated test suites (`game/tools/run_tests.sh`).

Whether AI tools helped draft the 24–25 Oct story and design documents is not recorded in the repository; the authors should add that here if so.

## Where prompts are logged

- **Every generation:** [production/AI_PROMPT_LOG.md](../production/AI_PROMPT_LOG.md), one row per generation, newest board work at the top.
- **Long prompts:** stored on the ElevenLabs Flows node named in the row, or in the files the row points to (for example [production/cutscenes/shots.csv](../production/cutscenes/shots.csv), the v8 cutscene notes and the board task text in `production/plan/tasks.json`).
- **From now on:** every board task adds its own row, as [GO_NEXT.md](../production/plan/GO_NEXT.md) requires, and this page is updated when a new tool is used.
