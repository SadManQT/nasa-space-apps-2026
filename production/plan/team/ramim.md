# Nafis Mohtasim Ramim — UI/UX and player-facing systems lead

**Share:** 30% of the team's work · **Board id:** `ramim` · Read with [MASTER_PLAN.md](../MASTER_PLAN.md) (your AI reads it; you do not have to).

You lead everything the player sees and touches in 2D: the HUD, menus, panels, puzzles, hints, messages, journal, progress and settings. You are also the team leader on the registration, so you help unblock others.

## How you work

Type **`continue(ramim)`** to your AI. It pulls, claims your next ready tasks (`board.py take --by "<Name>/<AI>"`), does them one by one inside your folders, tests, reviews, commits under your GitHub account and pushes ([GO_NEXT.md](../GO_NEXT.md) §0). Say **`go next`** instead for exactly one task.

**Your AI:** Any strong coding AI (Codex, Claude Code, Gemini CLI, Cursor). Ask it to read `game/scripts/ui/ui_design.gd` and `game-design/25_PLAYER_CLARITY_AND_MOON_JOURNEY.md` §1–§3 before any UI work.

## Your folders (only you edit these)

- `game/scripts/ui/`
- `game/scenes/ui/`
- `game/resources/ui/`
- `game/scripts/puzzles/`
- `game/scripts/comms/`
- `game/scripts/progression/`
- `game/scripts/settings/`
- `game/scripts/classmode/`
- `game/scripts/debrief/`
- `game/scripts/feedback/`
- `game/scripts/trainer/`
- `game/scenes/trainer/`
- `game/resources/trainer/`
- `game/scripts/main.gd`
- `game/scripts/dialogue/knowledge_service.gd`
- `game/resources/campaign/content/ui_text.json`
- `game/resources/campaign/content/how_to.json`
- `game/resources/campaign/content/journal_text.json`
- `game/resources/campaign/content/jobs.json`
- `game/resources/campaign/content/curriculum.json`
- `game/resources/campaign/content/messages/ch02.json`
- `game/resources/campaign/content/messages/ch03.json`
- `game/resources/campaign/content/messages/ch04.json`

Everything else belongs to someone else (MASTER_PLAN.md §7). Need a change there? File a task for its owner with `board.py add` and carry on.

## Your rules

- Every screen uses UiDesign (`game/scripts/ui/ui_design.gd`): its sizes, colours, glass panels and motion. No new colours or fonts.
- Player text: plain words, one goal, no codes; run `game/tools/test_player_text.gd` and extend it for every new screen.
- Puzzle logic stays pure in `game/scripts/puzzles/` (no UI inside it); panels follow the `open(route, target_id)` / `committed(result)` contract of `mission_table_panel.gd`. Atik wires panels into missions; do not edit `game/scripts/missions/`.
- Build UI in code where you can; if you use a `.tscn`, it lives under `game/scenes/ui/` and only you edit it.
- Commit under your own GitHub account, no AI co-author lines; log AI use in `production/AI_PROMPT_LOG.md` (one row per task; the file merges itself).

## Start here

The P-01 panel (M1-08), onboarding and the title screen (M1-18), the Mission Table restyle (M1-55), the hint player (M1-64), then the messages system (M1-56) and the endings and debrief (M1-19).

## Your work (35 open tasks, 86 effort points)

The board decides the real order and shows what is ready; this is the overview on 5 Nov 2026.

| Task | Milestone | Priority | Effort | Title |
|---|---|---|---|---|
| M1-37 | M1 | P0 | 5 | Four-player co-op Class mode: shared decisions, private role clues (as registered) |
| M1-08 | M1 | P0 | 3 | P-01 Commission & Plant: a real, interactive puzzle panel |
| M1-18 | M1 | P0 | 3 | First five minutes: title screen, onboarding and UX polish |
| M1-19 | M1 | P0 | 3 | Chapter 1 endings, decision replay and the science debrief |
| M1-31 | M1 | P0 | 2 | Make it fun: Chapter 1 game-feel and reward pass |
| M1-29 | M1 | P0 | 3 | Mission Trainer mode: every puzzle as a 5–10 minute training scenario |
| M1-55 | M1 | P0 | 3 | Mission Table made simple: guided first shift, plain toggles, before-and-after forecast |
| M1-56 | M1 | P0 | 3 | Messages: inbox, arrival toasts, unlock triggers and the message validator |
| M1-64 | M1 | P0 | 3 | Hint player: three progressive levels (nudge, animated explainer, worked method) in a polished overlay |
| M1-62 | M1 | P1 | 2 | Goal card text for Chapters 2-8: an authored goal, why, prompt, result and hint for every job |
| M3-2P | M3 | P1 | 3 | Chapter 2 puzzles P-03 and P-04 as real interactive panels |
| M3-3P | M3 | P1 | 3 | Chapter 3 puzzles P-05 and P-06 as real interactive panels |
| M3-4P | M3 | P1 | 3 | Chapter 4 puzzles P-07 and P-08 as real interactive panels |
| M3-90 | M3 | P1 | 3 | Remaining UI families: journal, discovery log, rover, greenhouse, credits |
| M3-98 | M3 | P1 | 3 | Full-campaign journal: People and Science tabs, flag-gated names, superseded entries, chapter pages, Class mode |
| M3-64 | M3 | P1 | 3 | The RPG layer: cadet record, skills, gear loadout, jobs board and rest |
| M3-67 | M3 | P1 | 3 | Moon trainer: free training sorties on the real terrain from the title menu |
| M3-2T | M3 | P1 | 2 | Chapter 2 messages: every scene joined to the next |
| M3-3T | M3 | P1 | 2 | Chapter 3 messages: every scene joined to the next |
| M3-4T | M3 | P1 | 2 | Chapter 4 messages: every scene joined to the next |
| M3-69 | M3 | P1 | 3 | The junior-astronaut curriculum: competencies, the Academy manual and 'what you learned' debriefs |
| M3-70 | M3 | P1 | 2 | Steam-quality settings, controls and saves |
| M3-72 | M3 | P1 | 3 | Chapter select, mission list, progress and achievements screens |
| M3-2U | M3 | P2 | 1 | Upgrade choice after Chapter 1 |
| M3-3U | M3 | P2 | 1 | Upgrade choice after Chapter 2 |
| M3-4U | M3 | P2 | 1 | Upgrade choice after Chapter 3 |
| M3-5P | M4 | P1 | 3 | Chapter 5 puzzles P-09 and P-10 as real interactive panels |
| M3-6P | M4 | P1 | 3 | Chapter 6 puzzles P-11 and P-12 as real interactive panels |
| M3-7P | M4 | P1 | 3 | Chapter 7 puzzles P-13 and P-14 as real interactive panels |
| M3-8P | M4 | P1 | 3 | Chapter 8 puzzles P-15 and P-16 as real interactive panels |
| M3-91 | M4 | P1 | 2 | All 128 upgrade profiles complete the campaign |
| M3-5U | M4 | P2 | 1 | Upgrade choice after Chapter 4 |
| M3-6U | M4 | P2 | 1 | Upgrade choice after Chapter 5 |
| M3-7U | M4 | P2 | 1 | Upgrade choice after Chapter 6 |
| M3-8U | M4 | P2 | 1 | Upgrade choice after Chapter 7 |
