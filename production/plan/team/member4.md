# member4 — QA and playtest lead

**Share:** 5% of the team's work · **Board id:** `member4` · Read with [MASTER_PLAN.md](../MASTER_PLAN.md) (your AI reads it; you do not have to).

You are the QA and playtest lead: you play the game with fresh eyes, run playtests with new players, and turn every problem into a clear task for the right person. Rename this slot to your name the first time (see below).

## First time: name this slot

Type `continue(<your name>)`. Your AI renames this slot to you on the board:
`python3 production/plan/board.py rename-member member4 <yourname> --name "<Your Full Name>"` (then commit and push `production/plan/`).
From then on your tasks are assigned to `<yourname>` and you always run `continue(<yourname>)`.

## How you work

Type **`continue(<your name>)`** to your AI. It pulls, claims your next ready tasks (`board.py take --by "<Name>/<AI>"`), does them one by one inside your folders, tests, reviews, commits under your GitHub account and pushes ([GO_NEXT.md](../GO_NEXT.md) §0). Say **`go next`** instead for exactly one task.

**Your AI:** Any AI that can read the repository and help you write reports (Claude, ChatGPT/Codex, Gemini). You do not need to write game code.

## Your folders (only you edit these)

- `production/qa/chapters/`
- `production/qa/playtests/`

Everything else belongs to someone else (MASTER_PLAN.md §7). Need a change there? File a task for its owner with `board.py add` and carry on.

## Your rules

- Write only inside `production/qa/chapters/` and `production/qa/playtests/` (plus screenshots in `production/qa/evidence/`).
- Every problem becomes a board task for the owner of the folder involved (see the ownership table in MASTER_PLAN.md §7):
  `python3 production/plan/board.py add --milestone M1 --for <owner> --title "<short problem>" --prompt "<where, steps to reproduce, what you expected, screenshot path>" --by "<YourName>/<AI>"`
- Use the chapter gate checklist (MASTER_PLAN.md §11) for every chapter QA.
- Commit under your own GitHub account, no AI co-author lines; log AI use in `production/AI_PROMPT_LOG.md` (one row per task; the file merges itself).

## Start here

The first-impressions playtest of today's Chapter 1 (M1-65). Later: Chapter 1 QA (M1-21), the learner playtest (M1-22) and the Chapter 2, 4, 6 and 8 QA.

## Your work (8 open tasks, 16 effort points)

The board decides the real order and shows what is ready; this is the overview on 5 Nov 2026.

| Task | Milestone | Priority | Effort | Title |
|---|---|---|---|---|
| M1-21 | M1 | P0 | 2 | Chapter 1 full playthrough QA with screenshots |
| M1-22 | M1 | P1 | 2 | Learner playtest (5+ players) with anonymous metrics |
| M1-65 | M1 | P1 | 2 | First-impressions playtest of today's Chapter 1: what confuses a new player |
| M3-2Q | M3 | P1 | 2 | Chapter 2 playthrough QA |
| M3-4Q | M3 | P1 | 2 | Chapter 4 playthrough QA |
| M3-6Q | M4 | P1 | 2 | Chapter 6 playthrough QA |
| M3-8Q | M4 | P1 | 2 | Chapter 8 playthrough QA |
| M2-11 | M2 | P0 | 2 | 12 Nov offline dry run and fallback video |
