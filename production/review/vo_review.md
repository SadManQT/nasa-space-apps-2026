# Voice lines: listening pass (4 Nov 2026)

All 383 spoken lines of `production/audio/vo_lines.csv` are generated (ElevenLabs eleven_v4, cast in `production/audio/voice_cast.csv`), mastered by `production/tools/master_vo.py` (best of two takes by Whisper word match; -16 LUFS, mono 44.1 kHz Vorbis; Earth-link and radio band-pass, aged recorder for stored recordings) and present at their `voice_file` paths. The two `text` rows are on-screen messages and are not voiced. Per-line prompts, both transcripts and the chosen take are in `production/audio/vo_takes/<line_id>.json`; dry masters in `production/audio/vo_masters/`.

The automated pass is a transcript check, not a listen: Whisper confirms the words, not the acting. Chapter detail: [CH01–CH02](vo_review_CH01-CH02.md), [CH03–CH04](vo_review_CH03-CH04.md), [CH05–CH06](vo_review_CH05-CH06.md), [CH07–CH08](vo_review_CH07-CH08.md).

## Listen first (Sadman)

| Line | Speaker | Why |
|---|---|---|
| EX-CH08-S10-L01 | Noor | First live voice, "Hello, Aurora. This is Noor." Whisper hears "Nor"; check the name and the emotion |
| EX-CH05-S05-L01 | Ferreira | The confession; judge the pause and weight |
| EX-CH08-S09-L02 | Rafi | "ALO42 sent." is read letter by letter ("A.L.O. 4-2"); decide if that is right |
| EX-CH04-S09-L03 | Amara | Heard "Predictions saved" for "Prediction saved" |
| EX-CH01-S02-L03 | Amara | Heard an extra "But" before "the station still can" |
| EX-CH08-S05-L03 | — | Heard "To here" for "Two here" |
| EX-CH05-S10-L04, EX-CH06-S03-L01 | Rao / — | "Every one" may sound like "everyone" |
| EX-CH05-S12-L02 | — | Whisper heard "11 other volt specimens" in both takes; check the words |
| EX-CH04-S02-L02 | Ferreira | How she says "Rafi" |
| EX-CH04-S12-L03 | Ferreira | 6.5 s; the pause before an admission |
| EX-CH03-S09-L01, EX-CH03-S10-L01, EX-CH03-S10-L04 | Mei | Grief scene; quiet and sincere? |
| Rafi safety lines (EX-CH04-S04-L01, S05-L03, S06-L03 and the CH07/CH08 roll call and tether watch) | Rafi | Never jokey |
| EX-CH02-S01-L01, EX-CH02-S10-L03 | Ferreira / N. | Radio and aged-recorder treatment |
| EX-CH06-S10-L02 | Rafi | "Here." is 0.68 s; works as a channel check? |

Accepted Whisper spellings (not errors): Alo as Aloe, Tara as Terra, Noor as Nor/Nur, Ferreira as Fereide/Fajeta, Rafi as Raffi, Mei as May, colour/color, glovebox/glove box, N.R./NR.
