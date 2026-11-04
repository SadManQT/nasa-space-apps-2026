# SFX review (2026-11-04)

All 35 effects generated with ElevenLabs Sound Effects v2 (`eleven_text_to_sound_v2`), flow `KPOnumryaaZbpjgtOfl1`. Variations were picked by analysis only (nobody has listened). Credits spent about 2050 (1780 first pass plus 273 for the three re-rolls) of the 100,000 cap. Full prompts are in `production/ai_log_parts/sfx.md`. Masters (original MP3) are in `production/audio/sfx_masters/`.

Export: Ogg Vorbis 48 kHz via soundfile. Loops: -24 LUFS integrated, peak limited to -1 dBFS, no fades. One-shots: leading silence trimmed to about 8 ms, 3 ms fade-in, 40 ms fade-out, peak -3 dBFS. Science rule: no airborne exterior sound was requested; ROVER_CHASSIS and QUAKE_CONTACT prompts demand structure-borne only.

**Variations compared:** the 18 nodes from the first run have 4 takes; the second run hit a rate limit (429) on some takes so those nodes have 2 to 3 takes (no take failed after starting). Water transfer take 2 was queued and finished later.

| Effect | Chosen take | Duration | Peak dBFS | LUFS | Loop seam | Why | Human listen |
|---|---|---|---|---|---|---|---|
| SFX_FAN_NORMAL | #2 of 4 | 12.0 s | -13.0 | -23.9 | +0.6 dB end-vs-start RMS(50ms); sample jump 0.0009 | Closest seam (+0.6 dB) and steadiest level of 4 (window level sd 2.0 dB); not the loudest source so no hiss boost | no |
| SFX_FAN_LOWPOWER | re-roll take F#2 of 4 | 12.0 s | -19.9 | -30.0 | +0.4 dB end-vs-start RMS(50ms) | New prompt gave a properly audible low drone (source rms -21 dBFS, vs -59 before). Spectrum: 99% of energy under 300 Hz, centroid 81 Hz (normal fans 112 Hz), slow level pulsing (sd 3.3 dB), seam 0.4 dB; the other three were similar. Normalised to -30 LUFS, 6 dB under the normal fans | YES: confirm it reads as a fan hum, not a drone or rumble |
| SFX_GREENHOUSE_FAN | #3 of 4 | 12.0 s | -13.1 | -24.3 | -0.1 dB end-vs-start RMS(50ms); sample jump 0.0111 | #3: smallest seam (+0.2 dB), flat level (sd 0.6 dB), no transients (#4 had a -13.8 dBFS spike) | check the lamp hum is audible |
| SFX_PUMP_PRESSURE | #1 of 4 | 10.0 s | -13.8 | -23.9 | +1.6 dB end-vs-start RMS(50ms); sample jump 0.0002 | #1: seam -1.6 dB, stable (sd 2.3), no silence | no |
| SFX_WATER_TRANSFER | #2 of 4 | 10.0 s | -11.8 | -24.1 | +0.2 dB end-vs-start RMS(50ms); sample jump 0.0097 | #2: seam -0.2 dB, steady; all four were similar | check it reads as water in pipes, not rain/hiss |
| SFX_VALVE_DETENT | #2 of 4 | 0.42 s | -2.9 | -26.0 | - | #2: compact (active 0.37 s), hits immediately; #1 had a second click at 0.5 s | check it is one click (analysis shows a short ratchet of ~3 transients) |
| SFX_GLOVE_PORT | #1 of 4 | 1.29 s | -3.1 | -26.7 | - | #1: two distinct events (hands in), strong level; #3 was very quiet | no |
| SFX_BRUSH_CONTACT | #1 of 4 | 1.34 s | -3.0 | -28.2 | - | #1: two to three light strokes as asked (others had 7-8 busy onsets) | source is very quiet (peak -23 dBFS), so it was boosted 20 dB: check hiss |
| SFX_SEED_TICK | #1 of 4 | 1.36 s | -3.3 | -25.7 | - | #1: handful of 6 ticks then settle, no long gap | no |
| SFX_SHUTTER_OPEN | #2 of 4 | 1.78 s | -2.9 | -34.3 | - | #2: slide then end click, strongest of the three | check the latch click lands at the end |
| SFX_DOOR_LATCH | #1 of 4 | 0.77 s | -3.0 | -26.7 | - | #1: clack then click (4 transients over 0.8 s) vs 6 in #2 | no |
| SFX_HATCH_SEAL | #1 of 4 | 2.33 s | -3.0 | -23.4 | - | #1: full sequence (thunk, lock, hiss tail); #2 was only 1.4 s of content | check hiss is interior and not too loud |
| SFX_AIRLOCK_CYCLE | #1 of 4 | 5.54 s | -3.0 | -15.9 | - | #1: level falls steadily across 5.5 s (start 28 dB louder than end) as pressure equalises | hiss is loud after peak normalisation (-15.9 LUFS); duck in mix |
| SFX_SUIT_BREATH | #2 of 4 | 10.0 s | -3.1 | -24.0 | +0.0 dB end-vs-start RMS(50ms); sample jump 0.0014 | #2: clear breath modulation (sd 6.9 dB) with no gaps and a seam of 0.0 dB; #3 had a 0.9 s near-silent gap | YES: confirm it sounds like breathing and has no vocal artefacts |
| SFX_RADIO_LOCAL_IN | #2 of 4 | 1.2 s | -2.9 | -18.7 | - | #2: one compact chirp (0.3 s active), good level; #1 was weak (-16 dBFS) and fragmented | check it is a two-note chirp |
| SFX_RADIO_EARTH_IN | #2 of 4 | 2.44 s | -3.0 | -19.1 | - | #2: chirp series from 0.5 s with echo repeats; #1 was silent for 1.8 s | check latency/echo texture |
| SFX_RADIO_EARTH_LOST | #2 of 4 | 3.48 s | -2.9 | -12.8 | - | #2: usable level (-20 dBFS peak) vs #1 (-39 dBFS) | check it fades to silence |
| SFX_RECORDER_AGED | #3 of 4 | 10.0 s | -9.1 | -24.0 | +0.2 dB end-vs-start RMS(50ms); sample jump 0.0051 | #3: seam -0.1 dB, no gaps; #1 had a -3.6 dBFS pop | check for crackle character |
| SFX_ALERT_PARTICLE | re-roll, edited (see below) | 1.05 s | -3.0 | n/a (short) | - | Eight re-roll takes (two prompts) never gave three separated beeps (they came back continuous or one to two beeps). Three clean beeps were built by tiling the first beep (0.19 s) of take Q#2 three times with 0.22 s silences; envelope check shows three beeps with full silence between | YES: confirm tone is a clean beep and the triple pattern reads as an instrument alarm |
| SFX_ALERT_PRESSURE | #2 of 3 | 2.12 s | -2.9 | -8.7 | - | #2: separated tones with gap, peak -3 dBFS | check descending two-tone |
| SFX_ALERT_STRUCTURAL | #2 of 3 | 2.69 s | -2.9 | -17.0 | - | #2: exactly three pulses 1 s apart | check pulse tone |
| SFX_QUAKE_CONTACT | #1 of 3 | 4.9 s | -2.9 | -23.6 | - | #1: builds from 0.7 s then fades over 4.9 s; louder source than #2 | check no airborne boom |
| SFX_CUP_RATTLE | #2 of 3 | 1.82 s | -3.0 | -27.5 | - | #2: 8 clinks then fade (#1 had 12) | no |
| SFX_CLAMP_SEAT | #2 of 2 | 0.8 s | -2.9 | -25.0 | - | #2: starts immediately, 0.75 s active (#1 had 0.5 s dead lead) | no |
| SFX_CONNECTOR | #1 of 3 | 0.97 s | -2.9 | -26.7 | - | #1: slide then lock, 3 transients | no |
| SFX_BREAKER_RESET | #1 of 2 | 0.33 s | -3.0 | n/a (short) | - | #1: single clunk | no |
| SFX_BATTERY_SWAP | #2 of 2 | 2.8 s | -2.9 | -25.4 | - | #2: two actions with 1.2 s gap (#1 gap 1.55 s) | no |
| SFX_CONTROLLER_POWERUP | re-roll take D#3, edited | 2.12 s | -3.0 | n/a | - | Eight re-roll takes: none had a single end beep cleanly (rising sweeps with no beep, or an extra blip). D#3 had a hum and a beep in its last 0.2 s; an earlier stray blip was cut out (hum 0 to 1.62 s, 0.3 s gap, final beep 2.28 s to end). Envelope shows hum then silence then one beep | YES: confirm one beep after the hum, no audible splice |
| SFX_ROVER_CABIN | #2 of 2 | 12.0 s | -11.3 | -24.0 | +0.5 dB end-vs-start RMS(50ms); sample jump 0.0003 | #2: seam -0.5 dB, steady (sd 2.1) | no |
| SFX_ROVER_CHASSIS | #1 of 2 | 12.0 s | -8.7 | -24.0 | -0.5 dB end-vs-start RMS(50ms); sample jump 0.0052 | #1: seam +0.5 dB, steady, lower crest than #2 | check there is no airy/wind texture (vacuum rule) |
| SFX_SCANNER_BEEP | #1 of 3 | 1.48 s | -3.1 | -16.1 | - | #1: sweep then double beep at 0.8 s | check peak level |
| SFX_CAMERA_SHUTTER | #2 of 2 | 0.35 s | -3.0 | n/a (short) | - | #2: single transient (#1 had 4) | no |
| SFX_UI_CONFIRM | #1 of 3 | 0.66 s | -3.0 | -19.2 | - | #1: short and soft (rms -28 vs -25) | check pitch rises |
| SFX_UI_SOFT_ERROR | #2 of 2 | 0.8 s | -2.9 | -20.7 | - | #2: two-note shape (one clear second onset) | check it is gentle |
| SFX_UI_SHIFT_COMMIT | #1 of 2 | 1.48 s | -3.0 | -15.5 | - | #1: louder source; chime at 1.1 s | check thunk then chime |

## Things a human should listen to first
- SFX_FAN_LOWPOWER (very quiet source, boosted 35 dB), SFX_SUIT_BREATH, SFX_ALERT_PARTICLE (may not read as beeps), SFX_CONTROLLER_POWERUP (single beep?), SFX_BRUSH_CONTACT (hiss), SFX_ROVER_CHASSIS (no airy wind).
- Loop seams measured as small RMS and sample differences (all under 3 dB, under 0.012 sample jump); no crossfade was applied. Spectral continuity was not checked.
- Levels: short clips under 0.4 s have no LUFS value; peaks are -3 dBFS. Alerts are loud by RMS (-9 to -17 LUFS) but not clipped; beds sit at -24 LUFS, so set bus gains in the mix, especially SFX_AIRLOCK_CYCLE and SFX_RADIO_EARTH_LOST which are loud after peak normalisation.

## Re-roll round (2026-11-04)
Coordinator asked for new attempts at SFX_ALERT_PARTICLE, SFX_CONTROLLER_POWERUP and SFX_FAN_LOWPOWER. Each got a first re-roll (4 takes), and the particle and controller effects a second re-roll (4 takes) after every take failed the onset checks. Flow nodes: `*_v2` and `*_v3` in the same flow. SFX_ALERT_PARTICLE and SFX_CONTROLLER_POWERUP are therefore edited generations (assembled and cut from generated audio); the unedited MP3 of the source take is in sfx_masters. The earlier takes of those two are overwritten in the game files.
