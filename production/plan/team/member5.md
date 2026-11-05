# member5 — Science, story and accessibility reviewer

**Share:** 5% of the team's work · **Board id:** `member5` · Read with [MASTER_PLAN.md](../MASTER_PLAN.md) (your AI reads it; you do not have to).

You are the science, story and accessibility reviewer: you make sure every claim is true, the story connects, and everyone can play. Rename this slot to your name the first time (see below).

## First time: name this slot

Type `continue(<your name>)`. Your AI renames this slot to you on the board:
`python3 production/plan/board.py rename-member member5 <yourname> --name "<Your Full Name>"` (then commit and push `production/plan/`).
From then on your tasks are assigned to `<yourname>` and you always run `continue(<yourname>)`.

## How you work

Type **`continue(<your name>)`** to your AI. It pulls, claims your next ready tasks (`board.py take --by "<Name>/<AI>"`), does them one by one inside your folders, tests, reviews, commits under your GitHub account and pushes ([GO_NEXT.md](../GO_NEXT.md) §0). Say **`go next`** instead for exactly one task.

**Your AI:** Any AI that can read the repository and the NASA sources with you (Claude, ChatGPT, Gemini). You do not need to write game code.

## Your folders (only you edit these)

- `production/review/`
- `production/qa/act1/`
- `production/qa/full_campaign/`
- `production/qa/dry_run/`
- `docs/challenge-statement-2026.md`
- `production/qa/chapters/`

Everything else belongs to someone else (MASTER_PLAN.md §7). Need a change there? File a task for its owner with `board.py add` and carry on.

## Your rules

- Write only inside `production/review/`, `production/qa/act1/`, `production/qa/full_campaign/`, `production/qa/dry_run/` and your chapter folders in `production/qa/chapters/`.
- Check claims against the source fixtures in `game/resources/data/nasa/` and `docs/SCIENCE_AND_DATA.md`; label each verdict correct / wrong / unclear.
- File every needed fix as a board task for the file's owner:
  `python3 production/plan/board.py add --milestone M3 --for <owner> --title "<short>" --prompt "<claim, where, source, fix>" --by "<YourName>/<AI>"`
- Commit under your own GitHub account, no AI co-author lines; log AI use in `production/AI_PROMPT_LOG.md` (one row per task; the file merges itself).

## Start here

Paste the official challenge statement (M0-12, a human task). Then the science fact-check of Chapters 1–4 (M3-75, ready once Sadman's Chapter 1 messages land) and the Chapter 3, 5 and 7 QA.

## Your work (7 open tasks, 14 effort points)

The board decides the real order and shows what is ready; this is the overview on 5 Nov 2026.

| Task | Milestone | Priority | Effort | Title |
|---|---|---|---|---|
| M0-12 | M0 | P0 | 1 | Paste the official 28 Oct challenge statement into the repo |
| M3-3Q | M3 | P1 | 2 | Chapter 3 playthrough QA |
| M3-74 | M3 | P1 | 2 | Act One full playthrough QA: canon, learning and accessibility (Chapters 1-4) |
| M3-75 | M3 | P1 | 3 | Science fact-check: Chapters 1-4 player text, messages, hints and data cards against their sources |
| M3-5Q | M4 | P1 | 2 | Chapter 5 playthrough QA |
| M3-7Q | M4 | P1 | 2 | Chapter 7 playthrough QA |
| M3-92 | M4 | P1 | 2 | Full-campaign canon, learning and accessibility QA |
