# SIMULATED first-time players, 12 Nov 2026

> **This is not a learner playtest.** An AI reviewer played the game in its head as five first-time personas, using a fresh automated playthrough of all 96 scenes (`production/qa/evidence/qa_campaign/`: start and end screenshots plus `transcript.md`, captured today on the current build). No real players took part, so it **does not** satisfy M1-22. The learner playtest with 5 or more real players still runs with `learner_kit/FACILITATOR.md`. Use this report to fix obvious problems before real players arrive.

**Reviewed:** the transcript of every scene; 49 screenshots (every Chapter 1 scene start, the first three scenes of Chapters 2–8, nine chosen scenes and eight main panels).

**Personas:**
- **A:** age 10, slow reader
- **B:** age 12, presses fast
- **C:** age 13, reads everything
- **D:** age 15, science-keen
- **E:** first-time gamer

## Findings and what happened to each

| # | Problem (personas) | Evidence | Status |
|---|---|---|---|
| 1 | A red "too few shielded places" warning stays on screen in calm chapters (all) | Shown from CH01-S07 to CH08-S12 | **Fixed:** the storm-shelter row only warns during the Chapter 1 storm night (S07–S11) and the Chapter 7 storm (`matters_in` in ui_text.json) |
| 2 | The camera starts inside walls or behind crew (E, A) | CH02-S02, CH03-S01, CH07-S03, CH02-S03, CH05-S01 | **Open, filed:** spawn-camera framing per scene needs a room-by-room pass |
| 3 | The goal text is hard to read on bright ceilings (A, E) | Every CH01 shot | **Fixed:** stronger dark backing behind the goal (0.86) and the toast (0.8) |
| 4 | "· 7 m" reads like a time (A, E, B) | "Next ▸ … · 7 m" | **Fixed:** distances now read "7 m away" |
| 5 | Repetitive one-button chores (B, A) | CH01-S04 has 10 steps, CH02-S05 has 13, CH03-S02 has 6, CH03-S04 has 5 | **Open, filed:** merging steps changes canon jobs and tests, so it needs a design decision |
| 6 | Jargon in dialogue (A, E, B) | "Exposure resolves before drain. Read the gate." and others | **Kept:** these are voiced canon lines (STORY_FULL.md); the plain goal card and What now (H) explain each step |
| 7 | The Chapter 1 bloom is told, not shown (A, C) | CH01-S12 end | **Open, filed:** stage the bloom at the shutter |
| 8 | Numbers a careful player questions (D) | Battery maximum 20 → 32 → 26 without comment; decimal air; base air shown during EVA | **Partly fixed:** the strip shows one decimal. Capacity-change notices and hiding base air outside are filed |
| 9 | Panels overlap (all) | The "[ventilation fans]" caption over the Mission Table buttons; clipped calibration tabs | **Partly fixed earlier:** calibration fits at 720p. Sound captions hide behind open panels in play; the overlap in the evidence comes from the capture tool |
| 10 | No control help for first-time gamers (E, A) | No movement help in CH01-S01 to S03 | **Fixed:** a "Walk W A S D · Look Mouse · Use E · Help H · Pause Esc" strip at the top centre for the first three scenes |

## Persona journeys (simulated)

- **A (age 10):** relies on the waypoints. The red warnings made them think they had failed (now fixed). The Seven Shifts planner is the likeliest place to quit. Estimated 55–70 minutes for Chapter 1.
- **B (age 12):** gets through by pressing E and Space and learns less. Gets bored at the long care and inspection chains in Chapters 2–3. Estimated 25–30 minutes for Chapter 1.
- **C (age 13):** likes the story (the N. mystery, Kai's humour, the 42-seed count). Wants to see the bloom. Estimated 45 minutes.
- **D (age 15):** enjoys calibration, the impact flashes and the eclipse. Questions the HUD numbers (see 8). Estimated 35–45 minutes.
- **E (first-time gamer):** stuck at the start without controls (now fixed) and when the camera starts in a wall. Needs an adult. Estimated 70 minutes or more.

## What works (simulated)

- Kai's humour.
- The 42-seed harvest, Ferreira's confession and Noor's live call.
- "You must be the bee."
- Try first, then lock in ("nothing changes yet").
- Clear E prompts and sound captions.
- Text size, timer-free and assist settings.
- The large Messages text.
- The lunar surface and the final cotton shot.
