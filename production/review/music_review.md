# Music review (ElevenLabs Music v2.5, CUE-01 to CUE-12)

Generated 2026-11-04, flow zezng3TLxLAjzoxeLTyj, model eleven_music_v2_5, instrumental. Credits spent: 46,440 (cap 120,000). I could not listen: picks are by analysis (duration, Whisper vocal check, silence scan, EBU R128, 5 s RMS contour). Whisper printed '!' / 'you' on many takes, which is its usual hallucination on music, not singing. No take was rejected for vocals; the one phrase-like result is flagged under the sting.

Export: equal-power 4 s crossfade of tail into head for loops (output = source minus 4 s), 1-2 s fade-out for one-shots, ffmpeg two-pass loudnorm to -18 LUFS (CUE-09 low/mid stems -21 / -19.5 so intensity order is kept), 48 kHz stereo Ogg Vorbis (libsndfile, compression_level 0.2, written in 1 s chunks because one-call sf.write segfaulted libvorbis on Python 3.14). Masters (original mp3) are in production/audio/music_masters/.

Not done: nobody has listened to any of these. Stems for CUE-03 (tension) and CUE-09 are separate takes, not beat-aligned. CUE-04 and CUE-11 have no separate hold/sustain loop. Palette coherence and the motifs were requested in the prompts but are unverified by ear.

## CUE-01 Home Not Yet
- File: game/assets/audio/music/MUS_CUE-01_HomeNotYet.ogg (vorbis, 48000 Hz, 2 ch, 90.0 s)
- Prompt: shared palette sentence + "Curious, open and calm: soft sustained pads, sparse gentle solo piano with a fragile three-note rising figure played only occasionally, a few warm string long tones. Slow tempo around 70 BPM, no drums, very low density so speech can sit on top, steady even energy suitable for looping." (duration_seconds 94, 3 variations)
- Choice: 3 takes. b was dense and loud (-13 LUFS, LRA 2) so rejected for speech ducking; a swung 8 dB; c is sparse, even (-22 dB, LRA 4.6) with a natural fade in the last 5 s that the crossfade absorbs. Chose c (variation u03sHbXt6sLuNLR4rDl4).
- Loudness: -17.8 LUFS integrated, LRA 5.8 LU, sample peak -3.8 dBFS (decoded ogg)
- Seam: loop: last-50ms vs first-50ms RMS differ -2.3 dB, max sample step 0.0043
- Listen for: Is the three-note rise audible and fragile (not twee)? Does it stay out of the way under Ferreira? ready for Sadman's listen (not held for approval).

## CUE-02 Small Work
- File: game/assets/audio/music/MUS_CUE-02_SmallWork.ogg (vorbis, 48000 Hz, 2 ch, 72.0 s)
- Prompt: shared palette sentence + "Intimate, warm everyday-work feel: soft felt piano playing a gentle repeating pattern, light plucked strings, warm low pad, a very soft rhythmic tick like a quiet woodblock or brushed shaker. Tempo around 80 BPM, calm and cozy, steady even energy, loopable, no big builds." (duration_seconds 76, 2 variations)
- Choice: Chose b (2nViKB7anulhXsyGpUeW): steady -22 dB throughout; a opens 5 dB quieter then rises, less loop-friendly.
- Loudness: -17.9 LUFS integrated, LRA 4.2 LU, sample peak -1.4 dBFS (decoded ogg)
- Seam: loop: last-50ms vs first-50ms RMS differ -0.6 dB, max sample step 0.0014
- Listen for: Is the tick light enough to sit under tool-action sounds? Does the loop restart read as a new phrase?

## CUE-03 Last Light
- File: game/assets/audio/music/MUS_CUE-03_LastLight.ogg (vorbis, 48000 Hz, 2 ch, 45.0 s)
- Prompt: shared palette sentence + "Bittersweet sunset mood: begins with warm strings and soft piano over a low pad, a slow gentle swell with light tension from a low pulsing synth and soft muted percussion, then thins out and fades gradually to near silence in the final seconds. Slow tempo 60 BPM." (duration_seconds 45, 3 variations)
- Choice: 3 takes. a was loud and flat (-12.9 LUFS) with an abrupt late drop; c starts near silence (-44 dB) so there is no bed at the gate. Chose b (zncsAuwC2Xp1ouQrRgPz): starts at bed level, swells to -18.4 dB around 20 s, thins to -49 dB at the end. Note: the prompt gave one 45 s piece, not a separate tension stem; the swell is the tension layer.
- Loudness: -17.3 LUFS integrated, LRA 10.2 LU, sample peak -1.4 dBFS (decoded ogg)
- Seam: one-shot (fade-out, no loop)
- Listen for: Does the swell feel like tension without a sting? Is the last 5 s silent enough for the Earth-link-loss silence? A separate tension stem was not generated.

## CUE-04 First Flower
- File: game/assets/audio/music/MUS_CUE-04_FirstFlower.ogg (vorbis, 48000 Hz, 2 ch, 35.0 s)
- Prompt: shared palette sentence + "Earned quiet joy: starts with a single fragile solo piano three-note rising motif over a soft pad, builds gradually with warm strings and gentle bells into a lifting hopeful major-key peak at about 25 seconds, then settles into a soft sustained warm chord that holds to the end. Tender, never bombastic, no drums." (duration_seconds 35, 3 variations)
- Choice: 3 takes. Chose b (LDABgVswfwgijUwaXt0Y): level rises 12 dB in the first 10 s and holds, widest dynamic range (LRA 12.8). a barely builds (-30 to -25); c starts almost silent for 5 s. The lift lands earlier (about 10 s) than the 25 s asked for.
- Loudness: -18.5 LUFS integrated, LRA 12.8 LU, sample peak -1.4 dBFS (decoded ogg)
- Seam: one-shot (fade-out, no loop)
- Listen for: Does the lift feel earned? Is the hold tail usable as a sustain (the file fades over the last 1.5 s, there is no separate hold loop)?

## CUE-05 Unfinished
- File: game/assets/audio/music/MUS_CUE-05_Unfinished.ogg (vorbis, 48000 Hz, 2 ch, 60.0 s)
- Prompt: shared palette sentence + "Respectful, sombre minimal bed: very sparse solo piano single notes with long silences between them, a low soft string drone, a hushed pad. Slow 55 BPM, quiet dignity and loss, no percussion, very low energy, steady and loopable." (duration_seconds 64, 2 variations)
- Choice: Chose a (CJeQWRSniUr9d5z4GeoK): flat -22 dB for the first 35 s; b swells earlier and louder. Both contain a swell near 40-55 s (a: +6 dB), which is not strictly minimal.
- Loudness: -17.8 LUFS integrated, LRA 14.8 LU, sample peak -2.0 dBFS (decoded ogg)
- Seam: loop: last-50ms vs first-50ms RMS differ +1.8 dB, max sample step 0.0008
- Listen for: Does the swell around 40-55 s of the loop feel too big for grief? If so, fade the cue earlier than the loop end or regenerate with 'no swell'.

## CUE-06 Beyond Home (travel loop)
- File: game/assets/audio/music/MUS_CUE-06_BeyondHome.ogg (vorbis, 48000 Hz, 2 ch, 120.0 s)
- Prompt: shared palette sentence + "Cautious wonder, a slow journey across a cold barren landscape: deep soft pads, a slow held pulse on low piano that gradually becomes a gentle walking rhythm, light airy bells and sparse strings, restrained muted soft taps for percussion. Tempo around 76 BPM, steady even energy, loopable, no big climaxes." (duration_seconds 124, 2 variations)
- Choice: Chose a (pHngOX8MPvGaMyoLq5M3): -18.2 LUFS raw, LRA 3.5, even; b was 3 LU louder with the same shape.
- Loudness: -17.9 LUFS integrated, LRA 3.0 LU, sample peak -1.4 dBFS (decoded ogg)
- Seam: loop: last-50ms vs first-50ms RMS differ -0.1 dB, max sample step 0.0019
- Listen for: Does the walking rhythm emerge? Is it comfortable on a long road (no fatigue)?

## CUE-06 Beyond Home (discovery sting)
- File: game/assets/audio/music/MUS_CUE-06_BeyondHome_Sting.ogg (vorbis, 48000 Hz, 2 ch, 20.0 s)
- Prompt: shared palette sentence + "A short discovery moment: a gentle rising swell of warm strings and shimmering pad blooming into a luminous open chord with soft bells and a three-note rising piano figure, awe and wonder, then a long quiet decay to near silence. No drums, not loud." (duration_seconds 20, 2 variations)
- Choice: Chose a (HJRUA6XGnes1DnTJCxqe). b was almost inaudible (-36 LUFS, peak level about -48 dB) so rejected. Whisper returned the low-confidence phrase 'Virgin Mary' (logprob -4.2, no_speech 0.39) on a, treated as a hallucination on a choir-like pad, but a human should confirm there is no vocal.
- Loudness: -16.5 LUFS integrated, LRA 13.8 LU, sample peak -1.3 dBFS (decoded ogg)
- Seam: one-shot (fade-out, no loop)
- Listen for: Confirm the pad contains no wordless voice. Does it feel like discovery, in the same key as the travel loop (not checked)?

## CUE-07 A Name
- File: game/assets/audio/music/MUS_CUE-07_AName.ogg (vorbis, 48000 Hz, 2 ch, 45.0 s)
- Prompt: shared palette sentence + "Relief and a gentle invitation: soft solo piano playing a patient two-note question-and-answer interval, a warm cello line answering it, delicate airy pad. Slow tempo 66 BPM, tender, unpressured, very quiet, no drums, ending in a long sparse quiet tail that can loop." (duration_seconds 49, 2 variations)
- Choice: Chose a (SFDRlLswLpehXlq2DDDC): steadier; b fades to near silence after 35 s (a better 'quiet tail' but a poor loop).
- Loudness: -17.9 LUFS integrated, LRA 10.7 LU, sample peak -1.4 dBFS (decoded ogg)
- Seam: loop: last-50ms vs first-50ms RMS differ -2.3 dB, max sample step 0.0078
- Listen for: Is the answering interval recognisable as the Noor motif? Seam RMS differs 2.3 dB, listen to the loop point.

## CUE-08 Red Ring
- File: game/assets/audio/music/MUS_CUE-08_RedRing.ogg (vorbis, 48000 Hz, 2 ch, 90.0 s)
- Prompt: shared palette sentence + "Slow, awed, concentrated mood: wide slow-moving ambient pads with a deep warm tone and slowly shifting overtones, sparse piano notes, soft long strings, a very soft heartbeat-like low pulse. Slow tempo 58 BPM, shared wonder, nothing ominous, no crescendo, steady even energy, loopable." (duration_seconds 94, 2 variations)
- Choice: Chose b (bp7NlY7GEodHFDuDv6JU): quieter and more spacious (-21 dB, LRA 3.2); a was denser (-14.9 LUFS).
- Loudness: -17.9 LUFS integrated, LRA 2.4 LU, sample peak -3.8 dBFS (decoded ogg)
- Seam: loop: last-50ms vs first-50ms RMS differ +0.2 dB, max sample step 0.0003
- Listen for: Is the low pulse reassuring rather than ominous? Does it recede under the feeder instructions at low gain?

## CUE-09 All We Learned (low stem)
- File: game/assets/audio/music/MUS_CUE-09_AllWeLearned_low.ogg (vorbis, 48000 Hz, 2 ch, 120.0 s)
- Prompt: shared palette sentence + "Competence under pressure, LOW intensity stem in D minor at 90 BPM: dark steady ambient pad, soft low string drone, a quiet repeated piano ostinato, no percussion, calm focused tension, steady even energy, loopable." (duration_seconds 124, 2 variations)
- Choice: Chose a (hru4NRCjN1wpLhRdNlZj): flat and steady; b is 5 dB quieter and creeps up.
- Loudness: -20.9 LUFS integrated, LRA 4.0 LU, sample peak -4.6 dBFS (decoded ogg)
- Seam: loop: last-50ms vs first-50ms RMS differ +2.0 dB, max sample step 0.0076
- Listen for: Do the three stems share tempo and key when crossfaded? The stems are separate generations and were not beat-aligned, so check the transitions.

## CUE-09 All We Learned (mid stem)
- File: game/assets/audio/music/MUS_CUE-09_AllWeLearned_mid.ogg (vorbis, 48000 Hz, 2 ch, 120.0 s)
- Prompt: shared palette sentence + "Competence under pressure, MEDIUM intensity stem in D minor at 90 BPM: steady dark pad, the same piano ostinato but more insistent, pulsing staccato low strings, light soft percussion pulse of muted taps and soft toms, focused and determined, steady even energy, loopable." (duration_seconds 124, 2 variations)
- Choice: Chose a (xMQfP60lRdvEzOBd4VpA): ramps over 15 s then steady -22 dB; b starts near silence for 10 s. My first download of a was truncated (74 s); re-downloaded from a refreshed link and re-exported (no extra credits).
- Loudness: -19.4 LUFS integrated, LRA 4.9 LU, sample peak -4.3 dBFS (decoded ogg)
- Seam: loop: last-50ms vs first-50ms RMS differ +2.0 dB, max sample step 0.0047
- Listen for: As for low.

## CUE-09 All We Learned (high stem)
- File: game/assets/audio/music/MUS_CUE-09_AllWeLearned_high.ogg (vorbis, 48000 Hz, 2 ch, 120.0 s)
- Prompt: shared palette sentence + "Competence under pressure, HIGH intensity stem in D minor at 90 BPM: driving urgent rhythmic strings, firm soft-edged percussion with toms and a deep pulse, the same piano ostinato, swelling pads; controlled and determined, not chaotic, no distortion, no horror, steady energy, loopable." (duration_seconds 124, 2 variations)
- Choice: Chose a (z8ZJTyup6SEllD5SlIhk): reaches -17.7 dB by 45 s and holds; b similar but 1 dB quieter at the top. Both ramp up over the first 30-40 s, so after the loop crossfade the first 30 s are quieter than the rest (seam RMS 2.7 dB apart).
- Loudness: -17.9 LUFS integrated, LRA 13.9 LU, sample peak -2.7 dBFS (decoded ogg)
- Seam: loop: last-50ms vs first-50ms RMS differ +2.7 dB, max sample step 0.0017
- Listen for: Is the first half-minute too soft for a 'high' state? The runtime may start this stem at 30 s.

## CUE-10 Known Road
- File: game/assets/audio/music/MUS_CUE-10_KnownRoad.ogg (vorbis, 48000 Hz, 2 ch, 120.0 s)
- Prompt: shared palette sentence + "Determined steady forward motion with hopeful resolve: a warm walking rhythm on a soft low pulse and gentle muted percussion at a comfortable 84 BPM, warm strings with a steady ostinato, a solo piano motif, pad underneath. Moderate energy, no sudden hits, predictable comfortable rhythm, loopable." (duration_seconds 124, 2 variations)
- Choice: Chose a (1VP6Vdq11R5g2cMsAq8m): LRA 2.5, flat; b about 1 LU hotter.
- Loudness: -17.9 LUFS integrated, LRA 2.5 LU, sample peak -3.3 dBFS (decoded ogg)
- Seam: loop: last-50ms vs first-50ms RMS differ -2.6 dB, max sample step 0.0093
- Listen for: Is the rhythm comfortable (no sudden hits)? Seam RMS differs 2.6 dB, listen to the loop point.

## CUE-11 Hello Aurora
- File: game/assets/audio/music/MUS_CUE-11_HelloAurora.ogg (vorbis, 48000 Hz, 2 ch, 60.0 s)
- Prompt: shared palette sentence + "Belonging and heartfelt reunion: a soft warm pad swell opening gently, solo piano with a tender three-note rising motif answered by a warm string line so the motif is shared between two instruments, glowing and gentle. Slow 64 BPM, plenty of space in the middle, no drums, ending in a long warm sustained chord." (duration_seconds 60, 3 variations)
- Choice: 3 takes. b had long near-silent gaps (-38 to -47 dB), c had dips; chose a (lO4Ve5yPSdwortYAWtCJ): soft opening at -27 dB, glowing body around -19 dB, fades over the last 10 s. No separate sustain loop.
- Loudness: -17.9 LUFS integrated, LRA 12.0 LU, sample peak -4.1 dBFS (decoded ogg)
- Seam: one-shot (fade-out, no loop)
- Listen for: Does the motif pass between piano and strings? Is the first 10 s quiet enough for Noor's first words?

## CUE-12 What We Grew (finale)
- File: game/assets/audio/music/MUS_CUE-12_WhatWeGrew.ogg (vorbis, 48000 Hz, 2 ch, 90.0 s)
- Prompt: shared palette sentence + "Completion and gratitude: warm strings and solo piano building slowly and gracefully from quiet to a full but gentle luminous peak around 60 seconds, the three-note rising motif played by piano and strings together, then resolving softly into a calm warm ending. Hopeful, no drums, no loud final hit." (duration_seconds 90, 2 variations)
- Choice: Chose a (ar2OWO2WsvaWweVwgzVR): -35 dB start, builds to -16.8 dB at about 65 s, resolves to -27 dB then fades; b has no real build.
- Loudness: -18.0 LUFS integrated, LRA 11.5 LU, sample peak -2.6 dBFS (decoded ogg)
- Seam: one-shot (fade-out, no loop)
- Listen for: Does the peak feel earned and gentle (no loud final hit)?

## CUE-12 What We Grew (credits loop)
- File: game/assets/audio/music/MUS_CUE-12_WhatWeGrew_Credits.ogg (vorbis, 48000 Hz, 2 ch, 180.0 s)
- Prompt: shared palette sentence + "Gentle reflective credits music: unhurried solo piano and warm strings, soft pads, light touches of bells, calm warm hopeful mood at 72 BPM, even gentle energy throughout with no loud peaks and no drums, loopable." (duration_seconds 184, 2 variations)
- Choice: Chose a (KeM0dQxIN46uhYUE8xpt): flattest (LRA 2.7). Both raw takes were hot (-12 LUFS) and were attenuated.
- Loudness: -17.9 LUFS integrated, LRA 2.2 LU, sample peak -6.6 dBFS (decoded ogg)
- Seam: loop: last-50ms vs first-50ms RMS differ -0.7 dB, max sample step 0.0047
- Listen for: Is it too similar to the finale for the credits? Skip it mid-loop to check there is no sting.
