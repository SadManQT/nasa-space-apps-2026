# CS-01 cold open — v8 re-edit of the v7 shots (5 Nov 2026, task M1-51), with the Earth field (6 Nov, M1-52)

No generation, no credits: `production/cutscenes/v8/src/CS-01.json` re-cuts the v7 Seedance shots
(`production/cutscenes/v7/src/shots/CS-01-A/B.mp4`) into the opening that
[24_NARRATIVE_REVISION.md §7.1](../../game-design/24_NARRATIVE_REVISION.md) beats 2–4 ask for. The four
`EX-CH01-S01` lines leave the film and play in-engine at the mission table (the campaign already voices the
scene's lines after the film; M1-49 places them on their beats). `CUE-01` still enters after the charter.
The v7 spec and master stay in `production/cutscenes/v7/` as the previous edition.

The exterior is the **M1-45 fixed CS-01-A** (repainted in place on 5 Nov: the NASA 10 kW vertical arrays on 16 m
masts facing the low Sun, and a hard 0.53° Sun disc with no halo). The repaint kept the plate's dolly frame for frame,
so the porthole the cut dives into is where it was (0.514, 0.475 of the frame at the shot's last frame) and the spec
needed no change; the master and the game `.ogv` were rebuilt from it on 5 Nov.

## The cut (14.1 s, 1280x720, 24 fps)

| Time | Picture | Sound | Layer |
|---|---|---|---|
| 0.0–2.0 | Shot A wide: the masts on the rim, the low hard Sun on the horizon, hard shadows, black sky, no Earth; 0.8 s fade from black | **Digital silence** | caption `[no sound outside]` 0.5–2.7 |
| 2.0–6.0 | Shot A accelerates smoothly toward the station (log speed ramp, 1x → 5x) and dives into the porthole (push 1x → 5.5x over the last 1.1 s) | digital silence | |
| 5.13–6.03 | 0.9 s dissolve: the porthole's glow becomes the commons (shot B, its own porthole on the back wall) | `SFX_FAN_NORMAL` fades in over 2 s from 5.4 | caption `[ventilation fans]` 6.3–8.5 |
| 6.0–11.4 | Shot B: the four at the mission table; an eased push-in (1x → 2.3x) onto the battery hologram | fans | slate `Aurora Station · lunar south pole · 11 April 2046 · 06:00 UTC` + chip `Story (2046)` 6.4–10.6 |
| 11.4–14.1 | The gold band at the top of the hologram fills the frame's centre; 1 s fade to black | fans, 0.6 s fade | title `LAST LIGHT ACADEMY` 10.9–13.7 |

Shot C (Ferreira on the Earth screen) is not used: Ferreira's line is now heard in play, before the commit.

## Why these choices

- Beat 2 (2 s wide, total silence) is 0–2 s; beat 3 (the push through a viewport) is 2–6 s. The exterior stays
  silent for as long as it is alone on screen (0–5.13 s), not just the first 2 s, so the vacuum rule is never
  contradicted by a fade that starts early; the fans begin only once the dissolve into the commons is under way
  (ART_BIBLE §2 rule 7).
- No music in the film: beats 2–4 are silence, then fans. The v7 `CS-01.mp3` bed leaves with the old cut, and
  music first arrives with `CUE-01` after the charter is acknowledged (§7.1 beat 9, the canon cue rule).
- The speed ramp keeps the wide establishing frame (beat 2's image) and still reaches the viewport inside the
  12–15 s budget without a jump cut on the same axis.
- The push-in on shot B is sampled from a 4x upscale (`zoompan` on 5120x2880), so it moves in quarter pixels;
  at 2.3x the cel-shaded hologram stays clean enough for the 2 s title hold.
- The slate's chip uses the science-transparency label for fiction (`Story (2046)`, §2.12) as §7.1 beat 3 asks.
- The fan bed is the production master `production/audio/sfx_masters/SFX_FAN_NORMAL.mp3` at 0.5 gain, which lands
  the interior near the game's own bed level (about −29 LUFS against the runtime bed's −24 LUFS at −6 dB).

## Measurements (5 Nov, rebuilt from the M1-45 exterior)

`production/qa/evidence/M1-51_capture.sh` encodes the `.ogv`, probes it into `production/qa/evidence/M1-51_probe.txt`
and runs the campaign windowed for the screenshots. Results:

- Master `.mp4`: 14.17 s; `scdet` at thresholds 3, 5 and 10 finds no hard cut (the only join is the dissolve; the
  highest score anywhere is 2.4, at 5.0 s in the fast push into the porthole). Mix `.wav`: every sample is exactly 0 until 5.377 s.
- Game `.ogv` (Theora 1280x720, 24 fps, like the other 17 films): 14.21 s (the campaign reads 14.21 s from the stream); `scdet` t=10 finds no cut; 0–5.13 s (the
  exterior alone on screen) peak −inf dB, max sample 0; the first non-zero sample is at 5.346 s, inside the
  dissolve (Vorbis spreads the fan onset by about 30 ms); interior peak −18.4 dB, RMS −31.1 dB.
- In play: CS-01 opens a new expedition as video, runs to its end, speaks none of the S01 lines; then Kai's
  `EX-CH01-S01-L01` is voiced in play over the commons fan bed (`M1-51_after_film_first_line.png`).

## compose_cutscene.py additions used here

Shot objects (`in`/`out` trims, `ramp`, `zoom`), `transitions` with an overlap (`dissolve:0.9`), `captions`
(sound captions without a speaker), `texts` (slate with an optional chip), `title`, and `beds` (looped sound
beds faded in on a cue). Old specs (plain shot paths, `card`, `music`, `lines`) are unchanged.

## 6 Nov 2026: opening beat 1, the Earth field (M1-52)

The cut now opens on Earth (doc 24 §7.1 beat 1). `shots/CS-01-F.mp4` is 6 s of a mustard field in winter morning
wind: Veo 3.1 Quality, frames-to-video from Sadman's approved start frame
(`production/concept/opening_field/field_anime_v1_start_frame.png`, "A, anime"), take 1 of two. It hard-cuts to the
silent Moon exterior, so the wind-to-nothing cut teaches the vacuum rule with no words. Every later cue moved 6 s later.

| Time | Picture | Sound | Layer |
|---|---|---|---|
| 0.0–6.0 | The field: four-petal cross flowers in the foreground, mist, bare winter trees; a slow drift right and in; 0.8 s fade from black | `SFX_EARTH_FIELD_MORNING` (gain 0.7, about −27 LUFS), 0.8 s fade in, ends at 5.96 s | caption `[wind and birds]` 0.8–5.6 |
| 6.0 | **Hard cut** to shot A | wind stops; digital silence | |
| 6.0–20.2 | The M1-51 cut, unchanged, 6 s later | as before | `[no sound outside]` 6.5–8.7, `[ventilation fans]` 12.3–14.5, slate 12.4–16.6, title 16.9–19.7 |

- **Yellow matched to the band** (beat 4): the field's yellows measured 47.9° hue against the battery band's 39.1°
  (median) and 43.3° (highlights) in the title frame. `ffmpeg huesaturation=hue=-6:colors=y+r:strength=40` moved
  the field to 42.1°, between the two, and left the sky alone. The grade is baked into `CS-01-F.mp4`.
- **Sound caption:** doc 24 beat 1 says "no caption", meaning no slate over the field. The sound still gets
  `[wind and birds]`, like the film's other two sound captions, so a player with the sound off sees the wind stop at the cut.
- **Silence after the cut:** the wind bed ends 40 ms before the cut, so the mix is exactly 0 from 5.994 s to 11.371 s.
  The game `.ogv`'s Vorbis spreads ±1 LSB (−90 dBFS) for 27 ms after the cut, then 0 until the dissolve (M1-51 noted the same spread at the fan onset).
- **Length:** 20.2 s. The 12–15 s budget in beat 2–4 was for the M1-51 cut alone; beat 1 adds its 6 s.

Measurements and screenshots: `production/qa/evidence/M1-52_capture.sh` → `M1-52_probe.txt`, `M1-52_film_*.png`,
`M1-52_master_*.png` (either side of the cut), `M1-52_after_film_first_line.png`. Prompts: `production/ai_log_parts/M1-52.md`.
