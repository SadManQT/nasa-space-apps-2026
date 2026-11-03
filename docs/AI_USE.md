# Use of AI — Last Light Academy

Team The Last BrainCell · NASA Space Apps Challenge 2026 · *Build a Junior Astronaut Mission Trainer*
Written 3 November 2026 for the project page's **Use of AI** field. The full record of every generation (tool, model, exact prompt, inputs, result, human changes) is [production/AI_PROMPT_LOG.md](../production/AI_PROMPT_LOG.md). Log rows are cited below as *date · asset*, the first two columns of the log, so they can be found with a text search.

## Summary (paste-ready)

We are a team of six building a full 3D Moon-outpost game (8 chapters, 32 missions, 96 scenes) in the weeks before the hackathon, so we used AI where it saves the most time and where we have no specialist: 3D models, concept and turnaround images, character animation clips, voices, music, short cutscene video clips and much of the code. The story, characters, dialogue, puzzle rules and numbers, science mapping and every creative decision are the team's: AI tools turned our written designs and approved reference images into assets, and wrote code against our specifications. Every generation is logged with its prompt. Tools used: **Claude Code** (Anthropic) for pipeline scripts, prompts, documentation and orchestration; **OpenAI Codex** for code, code review and bug hunting; **Google Nano Banana Pro** (Gemini 3 Pro Image) for concept art, turnarounds, portraits and cutscene start frames; **OpenAI GPT Image 2.5 Sunburst** for a few frame edits; **Topaz Image Upscale** for 4x upscales; **Tripo AI** for 3D models and skeletons; **Meshy** for motion-capture animation clips and five text-to-motion story actions; **ElevenLabs** for voices and music (and as the workspace that runs the image and video models); **ByteDance Seedance 2.5** for cutscene video shots; **Antigravity** once, for a second-opinion asset review we then rejected. **Veo was not used.** No NASA dataset was given to a generative model; the NASA data plan is in [SCIENCE_AND_DATA.md](SCIENCE_AND_DATA.md). No tool was bought for this project; generations used free tools or credits on plans we already had.

## Tools one by one

### Claude Code (Anthropic)

| | |
|---|---|
| Why | One agent that can plan, write scripts and run the asset pipeline end to end, so the team's time goes into design and review. |
| What it did | Wrote the production pipeline in `production/tools/` (Blender clean-up, previews, quality gate, character build, cutscene composer, Godot sync); drafted the generation prompts for the image, video, voice and music tools from the team's [art bible](../production/ART_BIBLE.md) and asset lists; ran the Tripo, Meshy and ElevenLabs jobs; reviewed renders against the art bible ([visual_review.md](../production/review/visual_review.md)); wrote the [production handbook](../PRODUCTION_HANDBOOK.md), the team board and these disclosure documents; made the pitch video's Blender scenes, motion graphics, synthesized music and edit (see below). Model: Claude Opus 5.5 in the 3 Nov sessions; the model for the 25–30 Oct sessions was not recorded. |
| Representative prompts | User to Claude, 3 Nov: "read all the instructions … check if our project … is all good … fix all the bugs … make a plan so every AI of every PC can track …" (log: *2026-11-03 · Rules check, team board, test runner*). Prompts Claude wrote for other tools are in their rows below, for example "Prompts written from ART_BIBLE.md and the asset master list" (log: *2026-10-25 · Plant and prop concepts*). |
| Data it worked on | This repository: the team's story, design and art documents, the generated assets, and the official Bangladesh Participants Guide (for the rules check). |
| Human edits and checks | The user (Sadman) approves every design sheet before 3D credits are spent, approves or rejects each result, and approves every commit. Code Claude writes is reviewed by Codex. |
| Log rows | *2026-11-03 · Rules check, team board, test runner*; *2026-11-03 · Documentation drift fixes (board task M0-18)*; *2026-11-03 · AI-use disclosure (board task M0-17)*. Earlier Claude work appears in the "Human changes" and tool columns of the 25–27 Oct rows. |

### OpenAI Codex

| | |
|---|---|
| Why | A second, independent model for code: it writes runtime code, reviews code it did not write, and hunts bugs, so no AI's code goes unchecked. |
| What it did | 26 Oct: face expression and head-accent runtime with tests. 27 Oct: toon shaders, face atlas, hair springs, the hold layer and a [readiness audit](../production/review/codex_readiness_report.md); code review of the v7 player changes; independent second opinion on asset contact sheets. 3 Nov: a read-only [bug hunt](../production/review/BUGHUNT_2026-11-03.md) (0 P0, 10 P1, 10 P2) and the fixes for it. Models: GPT-6 (26 Oct) and gpt-6-astra, reasoning xhigh (27 Oct and 3 Nov). |
| Representative prompts | "Review these Godot 4.7 GDScript and shader changes … for real bugs only (crashes, wrong behaviour, edge cases, ordering problems). Do not edit files. For each finding give file:line, the failure scenario and a minimal fix." (log: *2026-10-27 · v7 runtime code*); "READ-ONLY bug hunt of the Godot 4.7 GDScript project … ranked P0/P1/P2 with file:line, repro and minimal fix" (log: *2026-11-03 · Bug hunt of game/*). |
| Data it worked on | The `game/` code, the handbook and the puzzle rules in [08_PUZZLE_DESIGNS.md](../game-design/08_PUZZLE_DESIGNS.md). |
| Human edits and checks | Claude reviews every Codex diff and reruns all test suites (`game/tools/run_tests.sh`); the user approves commits. Visual results of the toon/face work are not yet visually approved. |
| Log rows | *2026-10-26 · Character v4 Godot face runtime and tests*; *2026-10-27 · v7 runtime code*; *2026-11-03 · Bug hunt of game/*; *2026-11-03 · Bug fixes B01–B05, B09–B12, B17–B20*. |

### Google Nano Banana Pro (Gemini 3 Pro Image), run in ElevenLabs Flows and through Tripo

This is the only Gemini model we used. No Gemini chat or Gemini CLI work is recorded.

| | |
|---|---|
| Why | Fast concept art and consistent four-view turnaround sheets, which the 3D tools need as input; screen portraits; start frames for cutscene shots. |
| What it did | Style key frames (25 Oct), cast turnarounds through four art directions (stylised-realistic, v6 realistic, then the v7 anime style and its v8 fixes), 16 plant and prop concepts, 8 more prop concepts, three screen portraits (Rao, Noor 2034, Noor today) and cutscene start frames. |
| Representative prompts | "Edit this image. Keep the same composition... Remove the eyes completely from the plant... no eyes, no face, no mouth... Keep the left plant's stem clearly purple and the right plant's stem green..." (log: *2026-10-25 · STYLE-03 Alo key frame, no eyes*); "Edit this character turnaround sheet of [NAME] for 3D modelling. Keep everything about the character exactly the same ... Change ONLY the arms, so the pose is identical in all four views ..." (log: *2026-10-27 · v8 turnaround sheets*); "Anime cel-shaded game cutscene still in exactly the drawing style of the reference image ... Wide establishing shot of Aurora, a small lunar research base near the Moon's south pole ..." (log: *2026-10-27 · Cutscenes v7 start frames: CS-01-A/B/C*). |
| Data it worked on | Our text prompts, written from the art bible (Moon science rules: black sky, no haze, hard shadows; plants never have faces; no NASA logos; no readable text) and our own earlier approved images as references. |
| Human edits and checks | One take picked or all rejected per prompt (e.g. Rao take 2 rejected for text-like marks, Noor take 2 for a duplicated face); frames checked against the art bible before any video; plant faces removed and kept out; flags placed on the left shoulder. |
| Log rows | *2026-10-25 · STYLE-01, STYLE-02, STYLE-03, TURN-KAI … TURN-FER, Plant and prop concepts, Glovebox, crew seat, pollination kit concepts, Noor present-day portrait, CS-01 to CS-03 start frames*; *2026-10-26 · 8 prop concepts, CS-04 to CS-17 start frames, Redo round 2, Audit fixes*; *2026-10-27 · v6 portraits and turnarounds, v7 style tests, v7 anime turnarounds, v7 screen-only portraits, v8 turnaround sheets, v8 side views, Cutscenes v7 start frames*. |

### OpenAI GPT Image 2.5 Sunburst and Topaz Image Upscale v2 (in ElevenLabs Flows)

| | |
|---|---|
| Why | GPT Image: extra edits of a few cutscene start frames in the redo and audit rounds. Topaz: 4x upscale of the chosen turnaround views before 3D generation. |
| Representative prompts | Frame edits as written on the flow nodes (log: *2026-10-26 · Redo round 2*, *Audit fixes*); Topaz has no prompt (CGI model, 4x, face enhancement off). |
| Data it worked on | Our own generated frames and turnaround views. |
| Human edits and checks | Same frame review as above. |
| Log rows | *2026-10-26 · Redo round 2*; *2026-10-26 · Audit fixes*; *2026-10-27 · v7 anime turnarounds*; *2026-10-27 · v8 side views*. |

### Tripo AI

| | |
|---|---|
| Why | Turns an approved four-view sheet or one concept image into a textured 3D model, and auto-rigs characters, in minutes instead of days of modelling. |
| What it did | All five characters (several rounds; the installed cast is the v8 build), 24 plant and prop models, the skeletons (Mixamo-spec, 65 bones with fingers), and the models first made for the pitch video and reused in the game (20 installed). |
| Representative prompts | None: image-to-3D from our approved images ("No text prompt: image-to-3D from the four approved v7 views", log: *2026-10-27 · v7 character 3D models*). Settings and task ids are in each row. |
| Data it worked on | Our approved turnaround views and concept images. |
| Human edits and checks | Mei's first v8 model rejected (her left arm was built twice) and rebuilt; every model passes the automated gate (size, triangles, textures, floor, bones) and a visual review before it is marked verified ([asset_verification.md](../production/review/asset_verification.md), [visual_review.md](../production/review/visual_review.md)). Clean-up (decimate, scale, pivot, flag patches, hold poses) is scripted in Blender. |
| Log rows | *2026-10-25 · CH-KAI 3D model, CH-KAI rig, CH-AMA … 3D models + rigs, 15 props and plants, 22 reused props, PR_PollinationKit 3D model*; *2026-10-26 · 3D models of the 8 props above, v3 finger rigs*; *2026-10-27 · v7 character 3D models, v7 final skeletons, v8 character 3D models, v8 Mei 3D model, retakes, v8 final skeletons*. The original 7 Oct pitch-video prompts for the 20 reused models were not recorded. |

### Meshy

| | |
|---|---|
| Why | A library of motion-captured clips (walks, idles, sitting, talking) and text-to-motion for story actions no library has (pollinating, watering, repairing). |
| What it did | Motion-source rigs and preset clips for all five characters (retargeted onto the Tripo skeletons: 42 clips each), five story motions (Pollinate, Water, Inspect, Type, Repair), and on 26 Oct a v3 model rebuild that was later replaced. |
| Representative prompts | Pollinate: "A person stands at a waist-high plant tray, leans in slightly and gently dabs the centre of a small flower with a fine brush held in the right hand, careful and precise, then straightens up." (log: *2026-10-26 · Story motions for all five characters*). |
| Data it worked on | Our character models and our text prompts. |
| Human edits and checks | After the user reviewed the demo (shrugged shoulders, hip-forward stance, flapping arms) the retargeting was corrected; the Inspect motion was trimmed to its first 62 %. |
| Log rows | *2026-10-26 · Character rigs and animation, Story motions for all five characters, Character rebuild v3 models, v3 motion source rigs and clips*; *2026-10-27 · v7 motion-source rigs and clips, Inspect v3 story motion*. |

### ElevenLabs (voices, music, and the Flows workspace)

| | |
|---|---|
| Why | Adult character voices and an original score without a recording studio; Flows is also where Nano Banana Pro, GPT Image, Topaz and Seedance were run. |
| What it did | Voice lines for the first three cutscenes (eleven_v4), three music cues (eleven_music_v2_5), and stand-in lip-sync test lines. |
| Representative prompts | Canon dialogue with delivery tags, e.g. "[warm, gentle, a recorded message from long ago] If you are hearing this, Alo bloomed. [small smile] Good. Now Alo needs a friend." (log: *2026-10-27 · Cutscene v7 voice lines*); "Instrumental anime film score cue, 50 seconds. Opening: a quiet, spacious ambient pad and slow, gentle solo piano notes ..." (log: *2026-10-27 · Cutscene v7 music*). |
| Data it worked on | Our story text, word for word from [STORY_FULL.md](../full-game-story/STORY_FULL.md). |
| Human edits and checks | The words are never changed; music is trimmed, faded and ducked under speech; Earth-link and recorded lines get a radio filter in the mix. |
| Log rows | *2026-10-26 · Lip-sync test lines*; *2026-10-27 · Cutscene v7 voice lines*; *2026-10-27 · Cutscene v7 music*. |

### ByteDance Seedance 2.5 (in ElevenLabs Flows)

| | |
|---|---|
| Why | Short animated shots for cutscenes, generated from our start frames. |
| What it did | 23 shots in the earlier realistic style (25–26 Oct, now archived) and the anime cutscenes CS-01, CS-02 and CS-03 (27 Oct). **Three shots, CS-02-C, CS-03-B and CS-03-C, were refused when the credits ran out; no AI video exists for them.** In the cuts they are slow push-ins over their start frames, made with ffmpeg without AI. |
| Representative prompts | "Slow, steady cinematic push-in across the grey lunar ground toward the small base ..." (log: *2026-10-27 · Cutscene v7 video CS-01-A/B/C*). Prompts describe motion only, never dialogue. |
| Data it worked on | Our start frames. |
| Human edits and checks | Every shot checked on its start, middle and end frames against the science rules; stars in a sunlit sky and a horizon glow were removed in post; dialogue, captions and music are added in our own edit, not by the video model. |
| Log rows | *2026-10-25 · CS-01-A … CS-03-B videos*; *2026-10-26 · CS-04-A to CS-17-B videos, Redo round 2, Audit fixes*; *2026-10-27 · Cutscene v7 video CS-01-A/B/C, CS-02-A/B/C, CS-03-A/B/C/D, CS-02-C, CS-03-B, CS-03-C (refused generations)*. |

### Antigravity (Google)

| | |
|---|---|
| Why | Tried once as a second visual reviewer of asset contact sheets (25 Oct). |
| Result | 35 PASS, 5 FIX; checking each FIX against close-ups showed all five were wrong, so it is no longer used for asset review ([visual_review.md](../production/review/visual_review.md), "Second opinion"). It generated nothing in the game. |

### Veo

Not used. It is available in the ElevenLabs workspace, but no Veo generation is in the log.

### AI agents whose tool is not recorded

These rows are AI work, but the repository and commits do not say which tool or model did it. **The team must confirm them before submission.**

| Work | What it produced | Log row |
|---|---|---|
| Execution prompt library (27 Oct, commit `5f94bc0`) | `execution/`: 300 task prompts, contracts and indexes; documentation only | *2026-10-27 · Execution prompt library* |
| Campaign code, 2–3 Nov (commits `5f85eb6` to `ff09cfd`) | A bootstrap slice, then a supervisor and Workers A, B and C: campaign state and simulation, saves, rooms and missions for Chapters 1–8, the content catalog and accessible UI, with their tests ([production/review/execution/](../production/review/execution/)) | *2026-11-02 · Bootstrap commissioning slice*; *2026-11-02 to 11-03 · Worker A, Worker B, Worker C*; *2026-11-03 · Supervisor integration* |

The board task that ordered this disclosure names "Codex/Claude workers" for the campaign code; that is not confirmed by any file.

## The pitch video (7–10 October)

From the [README](../README.md): Claude Code wrote the Blender scene and animation scripts, the motion-graphics animations, the synthesized music and sound effects, and the edit that assembles the film and its subtitles; ElevenLabs made the narrator and character voices from our script; Tripo AI made the 3D character models. Character animations came from Adobe Mixamo; the solar-flare footage is real NASA/SDO footage. These generations predate the log, so their exact prompts are not recorded.

## Every generated file in `game/assets` and its log rows

| `game/assets/` | Files | Log rows |
|---|---|---|
| `characters/` | CH_Kai, CH_Amara, CH_Mei, CH_Rafi, CH_Ferreira | *2026-10-27 · v7 style tests, v7 anime turnarounds, v8 turnaround sheets, v8 side views, v8 character 3D models, v8 Mei 3D model, retakes, v8 final skeletons, v7 motion-source rigs and clips, Inspect v3 story motion*; *2026-10-26 · Story motions for all five characters*; face layers and hold poses are drawn by script, no AI (*2026-10-27 · v7 anime face layers*) |
| `plants/` | PL_Alo_Bud, PL_Alo_Bloom, PL_Alo_Pods, PL_Tara_Bloom, PL_Cotton_Young, PL_ZeroSeedlingTray | *2026-10-25 · Plant and prop concepts*, *15 props and plants* |
| `plants/` | PL_CropRack | *2026-10-25 · 22 reused props* |
| `props/` | PR_GrowthChamber, PR_MissionTable, PR_VaultCase, PR_SeedCase, PR_Glovebox, PR_MalapertRelay, PR_SurveyBeacon, PR_CrewSeat, PR_HandLight | *2026-10-25 · Plant and prop concepts*, *Glovebox, crew seat, pollination kit concepts*, *15 props and plants* |
| `props/` | PR_PollinationKit | *2026-10-25 · Glovebox, crew seat, pollination kit concepts*, *PR_PollinationKit 3D model* |
| `props/` | PR_IceScanner, PR_ManualGauge, PR_RepairClamp, PR_RelayController, PR_UplinkFeedthrough, PR_SampleHolder, PR_SeedPacket, PR_Mug | *2026-10-26 · 8 prop concepts*, *3D models of the 8 props above* |
| `props/` | PR_ControlConsole, PR_PowerPanel, PR_BatteryJar, PR_OxygenUnit, PR_WaterValve, PR_WaterWallPanel, PR_HatchDoor, PR_SupplyBundles, PR_Dosimeter, PR_Recorder2034, PR_Helmet, PR_CrewBunk, PR_AnnexDrum | *2026-10-25 · 22 reused props* (made for the pitch video) |
| `environment/`, `vehicles/` | EN_CorridorSegment, EN_ExteriorModule, EN_SolarMast, VH_Rover, VH_ReliefLander, VH_ZeroAscent | *2026-10-25 · 22 reused props* (made for the pitch video) |
| `cutscenes/` | CS-01_Arrival.ogv, CS-02_The_Horizon_Closes_One_Door.ogv, CS-03_Alo_Needs_a_Friend.ogv | *2026-10-27 · Cutscenes v7 start frames (both rows), Cutscene v7 video (both rows), CS-02-C, CS-03-B, CS-03-C (refused generations), Cutscene v7 voice lines, Cutscene v7 music, Cutscenes … assembled* |
| `ui/portraits/` | CH_Rao_screen.png, CH_Noor_present_portrait.png, CH_Noor_2034_portrait.png | *2026-10-27 · v7 screen-only portraits* |

## What the team did itself

- **Story and characters.** The story, cast, chapters and dialogue are the team's: the design documents in [docs/](.) (story, Season 1 campaign, game plan, gameplay and science plan) were committed by Abu Sayem Mohammed Tanvir on 24 Oct, the full game-design pack in [game-design/](../game-design/) by MD Atik Khan and Abu Sayem Mohammed Tanvir on 24 Oct, and the 10–14 hour story edition [STORY_FULL.md](../full-game-story/STORY_FULL.md) on 25 Oct (account `2405167-hub`). Every voice line and caption in the game is that text word for word.
- **Puzzle design.** All 16 puzzles and every game number come from [08_PUZZLE_DESIGNS.md](../game-design/08_PUZZLE_DESIGNS.md). AI tools implement and test those numbers; they are never allowed to change them.
- **Science mapping.** Which NASA observation supports which game moment, and what is observed, computed or invented, is set out in [SCIENCE_AND_DATA.md](SCIENCE_AND_DATA.md) and [16_SCIENTIFIC_ACCURACY.md](../game-design/16_SCIENTIFIC_ACCURACY.md). The science rules every asset must pass (black sky, no fog or wind, lunar gravity, faceless plants inside pressurised enclosures) are the team's.
- **Art direction and approvals.** Sadman directed every style change (stylised-realistic, then realistic, then anime because realistic was too heavy), approves each 2D design sheet before 3D credits are spent, reviewed the character demos and asked for the animation fixes, and approved the 25 Oct cast sheets and Ferreira's walk, which became the walk for every character. Rejected AI results are kept in the log as rejected.
- **Code review and integration.** Every commit is made from a team member's own GitHub account. AI-written code is cross-checked by a second AI and by the automated test suites (`game/tools/run_tests.sh`).

Whether AI tools helped draft the 24–25 Oct story and design documents is not recorded in the repository; the authors should add that here if so.

## From now on

Every task on the team board adds its own row to [AI_PROMPT_LOG.md](../production/AI_PROMPT_LOG.md) (tool, model, prompt or task id, inputs, result, human changes), as [GO_NEXT.md](../production/plan/GO_NEXT.md) step 7 requires. Update this page when a new tool is used.
