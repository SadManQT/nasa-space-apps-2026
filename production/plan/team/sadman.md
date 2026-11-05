# Khandaker Shadman Sakib Siddiquee — Producer, art and media lead, integrator

**Share:** 40% of the team's work · **Board id:** `sadman` · Read with [MASTER_PLAN.md](../MASTER_PLAN.md) (your AI reads it; you do not have to).

You are the producer, the art and media lead and the integrator. Everything that needs a premium tool or credits is yours, and so is anything that ties the team's work together.

## How you work

Type **`continue(sadman)`** to your AI. It pulls, claims your next ready tasks (`board.py take --by "<Name>/<AI>"`), does them one by one inside your folders, tests, reviews, commits under your GitHub account and pushes ([GO_NEXT.md](../GO_NEXT.md) §0). Say **`go next`** instead for exactly one task.

**Your AI:** Claude Code with Claude Fable 5.1 (3D environments, rooms, terrain — the environment lead) and Opus 5.5 at extra-high effort (writing, science, reviews; it continues Fable's work when Fable hits its limit), Antigravity, Muse (Blender), Gemini 4 Argon, Codex. Premium: Tripo and Meshy (3D), ElevenLabs (voice, music, effects), Veo/Flow and Seedance (video), Claude Motion — the Tweenkit plugin (science explainers). Your night shift (`production/tools/night_supervisor.sh`) works only your tasks.

## Your folders (only you edit these)

- `game/assets/`
- `game/scripts/audio/`
- `game/scripts/world/`
- `game/scenes/campaign/rooms/`
- `game/resources/campaign/rooms/`
- `game/scenes/world/`
- `game/scripts/content/`
- `game/resources/campaign/content/messages/ (ch01 and ch05-ch08)`
- `game/resources/campaign/content/presentation_media.json`
- `game/resources/campaign/content/explainers.json`
- `game/project.godot`
- `production/concept/`
- `production/models/`
- `production/terrain/`
- `production/cutscenes/`
- `production/audio/`
- `production/video/`
- `production/explainers/`
- `production/tools/`
- `production/qa/release/`
- `docs/`
- `game-design/`
- `full-game-story/`
- `PRODUCTION_HANDBOOK.md`

Everything else belongs to someone else (MASTER_PLAN.md §7). Need a change there? File a task for its owner with `board.py add` and carry on.

## Your rules

- Credits: only when a task says so, after the 2D sheet approval it needs; check the balance; never buy anything; log every generation (tool, model, exact prompt, inputs, result).
- You are the only one who edits `game/project.godot`, `presentation_media.json`, `PRODUCTION_HANDBOOK.md` and the story documents. Teammates file tasks for you instead.
- You sign every chapter gate (`production/qa/chapters/chNN/gate.md`) and tag releases.
- Review incoming tasks other members file for you (`board.py list --member sadman --status todo`) at least once a day; answer approvals quickly so nobody is blocked.
- Commit under your own GitHub account, no AI co-author lines; log AI use in `production/AI_PROMPT_LOG.md` (one row per task; the file merges itself).

## Start here

Rooms from the kit (M1-06), the LOLA terrain (M1-34, the night shift resumes its parked work), the Claude Motion pipeline (M1-63), Chapter 1 assets (M1-07) and the Chapter 1 message pack (M1-57), which sets the format Ramim follows for Chapters 2–4.

## Your work (45 open tasks, 116 effort points)

The board decides the real order and shows what is ready; this is the overview on 5 Nov 2026.

| Task | Milestone | Priority | Effort | Title |
|---|---|---|---|---|
| M0-11 | M0 | P0 | 1 | Team roster, roles and both registrations |
| M1-06 | M1 | P0 | 5 | Assemble the Chapter 1 rooms from the kit |
| M1-34 | M1 | P0 | 5 | Real south-pole terrain from NASA LRO LOLA elevation data |
| M1-24 | M1 | P0 | 2 | Fix the playtest and QA findings, then freeze the demo build |
| M1-57 | M1 | P0 | 2 | Chapter 1 messages: every scene joined to the next (at least 30 messages) |
| M1-59 | M1 | P0 | 3 | Explainer clips: the Godot clip pipeline, Chapter 1's clips, first-time cards and Journal How to |
| M1-60 | M1 | P0 | 3 | Chapter 1 science explainers: the polar Sun, Earth's position, crew needs, power, storm data, shielding, plant growth |
| M1-63 | M1 | P0 | 2 | Claude Motion explainer pipeline: install Tweenkit, house style, spec to video to game, two sample clips |
| M1-07 | M1 | P1 | 3 | Chapter 1 missing assets: Alo's early stages, Earth desk, UI kit |
| M1-52 | M1 | P1 | 2 | Opening beat 1: a 6 s Earth mustard-field shot and its wind-and-birds effect |
| M1-61 | M1 | P1 | 1 | Sound captions in the house style: on a panel, out of the walking view, no captions for interface clicks |
| M3-2A | M3 | P1 | 3 | Chapter 2 assets: EN_Airlock, PR_PaperBee |
| M3-2R | M3 | P1 | 3 | Chapter 2 rooms and locations |
| M3-3A | M3 | P1 | 3 | Chapter 3 assets: EN_ZeroAnnex, PL_Descendants, PR_Helmet_Roles, PR_PressedPetal, CH_Cadet_EVA |
| M3-3R | M3 | P1 | 3 | Chapter 3 rooms and locations |
| M3-4A | M3 | P1 | 3 | Chapter 4 assets: EN_Garage, EN_ColdTrap |
| M3-4R | M3 | P1 | 3 | Chapter 4 rooms and locations |
| M3-99 | M3 | P1 | 3 | Narrative props, plant stages and effects: Alo and Tara growth variants, nameplates, named mugs, clue props, two new SFX |
| M3-94R | M3 | P1 | 1 | Record the three approved M3-94 lines and the two M3-97 sound effects with ElevenLabs |
| M3-60 | M3 | P1 | 5 | The Moon you can walk: the region around the ridge on real terrain (Fable) |
| M3-66 | M3 | P1 | 3 | Explainer clips for every Chapter 2-4 mechanic (5-8 in M3-76) |
| M3-68 | M3 | P1 | 3 | Science explainers for Chapters 2-4 and the Moon trainer (5-8 in M3-77) |
| M3-5A | M4 | P1 | 3 | Chapter 5 assets: PL_Cotton_Seedling, PR_ImpactMonitor, CH_Ferreira_Duty, CH_Cadet_DutyLayer |
| M3-5R | M4 | P1 | 3 | Chapter 5 rooms and locations |
| M3-6R | M4 | P1 | 3 | Chapter 6 rooms and locations |
| M3-7R | M4 | P1 | 3 | Chapter 7 rooms and locations |
| M3-8A | M4 | P1 | 5 | Chapter 8 assets: EN_MalapertSummit, EN_RelayRoad, EN_NoorRooftop, CH_Noor, CH_Rao |
| M3-8R | M4 | P1 | 3 | Chapter 8 rooms and locations |
| M3-97 | M4 | P1 | 3 | Cutscene staging from the narrative revision: CS-15 call, CS-17 final garden, CS-18 lamp blink |
| M3-5T | M4 | P1 | 2 | Chapter 5 messages: every scene joined to the next |
| M3-6T | M4 | P1 | 2 | Chapter 6 messages: every scene joined to the next |
| M3-7T | M4 | P1 | 2 | Chapter 7 messages: every scene joined to the next |
| M3-8T | M4 | P1 | 2 | Chapter 8 messages: every scene joined to the next |
| M3-76 | M4 | P1 | 3 | Explainer clips for every Chapter 5-8 mechanic |
| M3-77 | M4 | P1 | 3 | Science explainers for Chapters 5-8 |
| M2-02 | M2 | P0 | 2 | NASA project page text, ready to paste |
| M2-03 | M2 | P0 | 2 | Video 2 (240 s local judging) script, shot list and subtitles |
| M2-04 | M2 | P0 | 2 | Record gameplay captures and narration for the videos |
| M2-05 | M2 | P0 | 3 | Edit Video 2 (≤240 s) with burned-in English subtitles |
| M2-06 | M2 | P0 | 1 | Upload Video 2 by 13 Nov 18:30 |
| M2-07 | M2 | P0 | 2 | Video 3 (30 s global) with English subtitles |
| M2-08 | M2 | P0 | 1 | Upload Video 3 by 14 Nov 09:00 |
| M2-10 | M2 | P0 | 1 | Fill in and submit the NASA project page |
| M2-09 | M2 | P1 | 2 | Seven-slide English deck (backup for the demo field) |
| M2-12 | M2 | P1 | 1 | Rehearse the live 240 s pitch for local judging (14 Nov 11:00) |
