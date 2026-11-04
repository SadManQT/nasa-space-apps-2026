# CS-01 cold open — v8 re-edit of the v7 shots (5 Nov 2026, task M1-51)

No generation, no credits: `production/cutscenes/v8/src/CS-01.json` re-cuts the three v7 Seedance shots
(`production/cutscenes/v7/src/shots/CS-01-A/B/C.mp4`) into the opening that
[24_NARRATIVE_REVISION.md §7.1](../../game-design/24_NARRATIVE_REVISION.md) beats 2–4 ask for. The four
`EX-CH01-S01` lines leave the film and play in-engine at the mission table (the campaign already voices the
scene's lines after the film; M1-49 places them on their beats). `CUE-01` still enters after the charter.
The v7 spec and master stay in `production/cutscenes/v7/` as the previous edition.

## The cut (14.1 s, 1280x720, 24 fps)

| Time | Picture | Sound | Layer |
|---|---|---|---|
| 0.0–2.0 | Shot A wide: the mast on the rim, low Sun, hard shadows, black sky; 0.8 s fade from black | **Digital silence** | caption `[no sound outside]` 0.5–2.7 |
| 2.0–6.0 | Shot A accelerates smoothly toward the station (log speed ramp, 1x → 5x) and dives into the porthole (push 1x → 5.5x over the last 1.1 s) | silence until 5.4 | |
| 5.1–6.0 | 0.9 s dissolve: the porthole's glow becomes the commons (shot B, its own porthole on the back wall) | `SFX_FAN_NORMAL` fades in over 2 s from 5.4 | caption `[ventilation fans]` 6.3–8.5 |
| 6.0–11.4 | Shot B: the four at the mission table; an eased push-in (1x → 2.3x) onto the battery hologram | fans | slate `Aurora Station · lunar south pole · 11 April 2046 · 06:00 UTC` + chip `Story (2046)` 6.4–10.6 |
| 11.4–14.1 | The gold band at the top of the hologram fills the frame's centre; 1 s fade to black | fans, 0.6 s fade | title `LAST LIGHT ACADEMY` 10.9–13.7 |

Shot C (Ferreira on the Earth screen) is not used: Ferreira's line is now heard in play, before the commit.

## Why these choices

- The exterior stays silent for its whole 6 s, not just the first 2, so the vacuum rule is never contradicted
  by a fade that starts early; the fans begin only once the dissolve is under way (ART_BIBLE §2 rule 7).
- The speed ramp keeps the wide establishing frame (beat 2's image) and still reaches the viewport inside the
  12–15 s budget without a jump cut on the same axis.
- The push-in on shot B is sampled from a 4x upscale (`zoompan` on 5120x2880), so it moves in quarter pixels;
  at 2.3x the cel-shaded hologram stays clean enough for the 2 s title hold.
- The slate's chip uses the science-transparency label for fiction (`Story (2046)`, §2.12) as §7.1 beat 3 asks.
- The fan bed is the production master `production/audio/sfx_masters/SFX_FAN_NORMAL.mp3` at 0.5 gain, which lands
  the interior near the game's own bed level (about −29 LUFS against the runtime bed's −24 LUFS at −6 dB).

## Measurements (master .mp4; the .ogv probe is written by `production/qa/evidence/M1-51_capture.sh`)

See `production/qa/evidence/M1-51_probe.txt` after the capture script has run. Master checks done in the edit
session: duration 14.1 s; `scdet` (threshold 3, 5 and 10) reports no hard cut (the only join is the dissolve);
`astats` on 0–5.4 s: peak −inf dB, max sample 0; interior peak about −18 dB, RMS about −31 dB.

## compose_cutscene.py additions used here

Shot objects (`in`/`out` trims, `ramp`, `zoom`), `transitions` with an overlap (`dissolve:0.9`), `captions`
(sound captions without a speaker), `texts` (slate with an optional chip), `title`, and `beds` (looped sound
beds faded in on a cue). Old specs (plain shot paths, `card`, `music`, `lines`) are unchanged.
