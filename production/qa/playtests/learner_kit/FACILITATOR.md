# Learner playtest kit (M1-22, M1-65)

One facilitator, five or more first-time players, about 35 minutes each. Everything below is on one page so you can run it straight from a phone.

## Before the players arrive (10 minutes, once)

1. Build or download the latest Windows build (GitHub Actions artifact of the newest `Native export smoke` run, or the release).
2. Start it with the playtest switch so it writes an anonymous log:
   - **Windows:** make a shortcut to `LastLightAcademy.exe`, open its Properties, and add ` -- --playtest` to the end of *Target*.
   - **macOS:** `open -a "Last Light Academy" --args -- --playtest`
   - **From the editor build:** `Godot --path game -- --playtest`
3. The log stores only in-game play time and events (jobs done, tries, hints, scenes, ending). No names, voices, faces or typed text.
4. Logs land in `%APPDATA%/Godot/app_userdata/Last Light Academy/playtest/` (Windows) or `~/Library/Application Support/Godot/app_userdata/Last Light Academy/playtest/` (macOS).

## Consent (players under 18)

- A parent or guardian is present and agrees out loud before starting. Note "consent given" on the sheet; do **not** write the child's name.
- Never record faces or voices of anyone under 18. Screenshots of the game screen only.

## The session (per player)

| Minute | What you do | What you say |
|---|---|---|
| 0 | Seat the player, headphones on, game at the title screen | "Play as if you were at home. I can't help, but I'll watch. Think out loud if you like." |
| 0–25 | Player presses **New expedition** and plays Chapter 1. **Stay silent.** | Only if the player is stuck for over 2 minutes: "What do you think you should try?" (note it) |
| 25 | Stop at a calm moment | "Thank you. Two quick questions." |
| 25–32 | Ask the questions below; write the answers word for word | |

Write on the observation sheet (copy the table per player):

| Time | What happened | Did they know what to do? (Y/N) | Note |
|---|---|---|---|
| | | | |

## Two questions (predict and explain)

1. **Predict:** "If the battery is full in daylight and you keep the air maker off, what happens to the extra sunlight?" *(Expected: it is lost; a full battery cannot store more, so it should be spent on air or the garden.)*
2. **Explain:** "Why did the crew put water in the wall before the storm?" *(Expected: water blocks radiation; the shelter wall protects the crew.)*

Score each 0 (no idea), 1 (partly), 2 (clear).

## After all players

```bash
python3 production/qa/playtests/learner_kit/summarise.py "<folder with the session_*.jsonl files>"
```

Paste the printed table into `production/qa/playtest-<date>.md`, add each player's two question scores, and list every confusion point (the `early_confusion` column plus your notes). File each real problem as a board task for its owner (`python3 production/plan/board.py add ...`).

The same kit covers the first-impressions test (M1-65): run it with 1–2 friends, and write `production/qa/playtests/first_impressions/report.md` with at least 10 observations and screenshots.
