# Cutscenes B — CS-07 to CS-12 (v8, 4 Nov 2026)

Agent: Claude (cutscene director-producer B). Board tasks M3-4C, M3-5C, M3-6C.
ElevenLabs flow: **"Last Light Academy — Cutscenes B (CS-07..12)"** `VuwkAWRO7pmMn1jfcAhB`
(https://elevenlabs.io/app/flows/VuwkAWRO7pmMn1jfcAhB).

Hard credit cap for this lane: **760,000**. Measured prices (estimate_only, 4 Nov):
Seedance 2.5 1080p = 6,265.4 credits/s (62,654 per 10 s); Nano Banana Pro 2K = 1,218 per image
plus ~609 per wired reference image (4 refs = 3,654, 5 refs = 4,263); eleven_music_v2_5 ≈ 909 per 30 s variation.
At this price the cap buys about 112 s of 1080p video after frames and music, so each cutscene is
planned at 15–22 s (lines start as the chapter card fades at ~3.8–4.5 s).

## Reference nodes on the flow (uploaded from the repo)

| Ref | Source | node |
|---|---|---|
| Kai sheet | concept/turnarounds_v8/kai/sheet_upscaled.png (2752 px JPEG) | op7eJONcM4Pmk1J8Iysl |
| Amara sheet | turnarounds_v8/amara | rjQtb3JiKdfR0lAaO1fX |
| Mei sheet | turnarounds_v8/mei | 13AeeI2XsNhgkCEBdzUp |
| Rafi sheet | turnarounds_v8/rafi | EsNWreWxpqhqGVg6Yj73 |
| Ferreira sheet | turnarounds_v8/ferreira | zwWAqCGzhHViLDoZaeTV |
| v7 style, exterior | frame at 3 s of v7/src/shots/CS-01-A.mp4 | AnxF5JrbCa4n3Q3ed1Dz |
| v7 style, commons crew | v7/src/shots/CS-01-B.mp4 @3 s | JN2I989U9OlXa9xkEn2o |
| v7 style, commons screen | v7/src/shots/CS-01-C.mp4 @3 s | wCmqTIizbRB9Kp9Ib0Ew |
| v7 style, power room | v7/src/shots/CS-02-C.mp4 @3 s | d2RcrqvqJteWLiKknEfm |
| Vault case | concept/props/vault_case/vault_case_v1.png | V1yCvRW3EhrmGX0O0UCS |
| Mug | concept/props/mug/mug_v1.png | TmVuSbHSSf0AdLaBeall |
| Hand light | concept/props/hand_light/hand_light_v1.png | rlkZLI3qUdiAikNjBfih |
| Mission table | concept/props/mission_table/mission_table_v1.png | 6xi4zJSNIAQFVcGDHYtN |
| Relief lander | models/final/VH_ReliefLander/preview/final_34.png | 07ufStt4O3x4RyIDpuk6 |
| Rover | models/final/VH_Rover/preview/final_34.png | LvYfgeuTRoOTQWjX8Vin |
| Rao screen | game/assets/ui/portraits/CH_Rao_screen.png | A3tAQ3YDfU8FTcLvFBVB |
| Noor present | game/assets/ui/portraits/CH_Noor_present_portrait.png | EDM1FA05qdJemrZ2bjZd |

Probe nodes (estimate only, never run): video cv3AUxi6mvZRIbxWXRwx, image 6crqEJYp4JbIcapjC53l, music QijDcY3PfeveQKj0eQ64.

## Credit ledger (running)

| Step | Credits | Running total |
|---|---|---|
| CS-07-A frame, 2 takes (5 refs) | 8,526 | 8,526 |
| CS-07-B frame, 2 takes (4 refs) | 7,308 | 15,835 |
| CS-07-A video 7 s | 43,858 | 59,693 |
| CS-07-B frame edit (remove beam), 1 take 2K | 1,827 | 61,520 |
| CS-08-A/B/C frames, 1 take each 2K (2/3/3 refs) | 8,526 | 70,047 |
| CS-09-A/B frames, 1 take each 2K (2/3 refs) | 5,481 | 75,528 |
| CS-07-B video 7 s | 43,858 | 119,386 |
| CS-08-C frame edit (four mugs) | 1,827 | 121,213 |
| CS-08-A video 4 s + CS-08-B video 7 s | 68,920 | 190,133 |
| CS-09-A edit (hair) + CS-09-B edit (Mei patch) | 3,654 | 193,787 |
| Music: CS-07/08/10/11/12, 2 variations each | 3,450 | 197,237 |
| CS-07-C 7 s + CS-09-A 8 s + CS-09-B 5 s videos | 125,309 | 322,546 |
| CS-08-C video 7 s | 43,858 | 366,404 |
| CS-10-A/B/C frames (3/3/2 refs) | 8,526 | 374,930 |
| CS-11-A/B, CS-12-A/B frames (2/3/2/2 refs); CS-11-B v1 rejected (khaki coveralls, Mei brown hair, Rafi lost beard and vest) | 10,354 | 385,284 |
| CS-10-B edit (Ferreira hair) | 1,827 | 387,111 |
| CS-10-A 6 s + CS-10-C 6 s videos | 75,185 | 462,296 |
| CS-12-A edit (remove "LIVE", hand light off) + CS-12-B edit (blank checklist card) + CS-11-B v2 frame | 6,699 | 468,995 |
| CS-11-A video 6 s (missing from the earlier row) | 37,593 | **506,588** |

### Run 2 (5 Nov, resume after the connector drop; cap for this run 253,000; spent 225,409.7, left 27,590.3)

Prices rose on 5 Nov: Seedance 2.5 1080p now 7,518.6 credits/s, 720p 3,360.9/s; Extend (720p) adds ~686/s of input video.
The workspace now lists only `bytedance-seedance-v2.5-us` (new nodes use it). Chained shots use Seedance 2.5 Extend (`bytedance-seedance-v2.5-extend-us`, wired to the previous shot's video), since the connector has no upload path for a locally extracted last frame.

| Step | Credits | Run 2 total | Lane total |
|---|---|---|---|
| Batch 1: CS-10-B 5 s 1080p (37,593.2), CS-11-B 6 s 1080p (45,111.9), CS-12-A 5 s 1080p (37,593.2), CS-12-B 4 s 720p (13,443.5), CS-11-C extend 6 s 720p (24,282.3) | 158,024.1 | 158,024.1 | 664,612.1 |
| CS-12-A retake v2 5 s 720p (node CNYDfEJtWkCrXTWY1rx6, session MQ8UeRVeqmV74289H4sE, gen pf0dE49ecszd6rgRV2kf) | 16,804.4 | 174,828.5 | 681,416.5 |
| CS-09-C extend of CS-09-A 6 s 720p (node fxCykAx8a4zZsyibjE97, session FXXnSB5EHDYFYqjnwbIn, gen MM7UCZ1QDXvejDNh8rEB) | 28,315.4 | 203,143.9 | 709,731.9 |
| CS-12-C extend of CS-12-A v2 6 s 720p (node sHQv2o0yfPdRRJFUF7jl, session kRW5Ka2QMfe8Dpb1GHde, gen lHTuy9wLvWJqlxtp3HgK) | 22,265.8 | 225,409.7 | 731,997.7 |

Batch 1 sessions (started 5 Nov): CS-10-B node SZBhtiMzIjNausuz4r6X session K9pf9aBwXMq9KHQOSEBS gen uIa5D2LOoDKQJxMILAPo; CS-11-B oPXLSbLFSUBefIVWUo0c / ODs2s8FWA9wxC4h5IE5W / 2WdEOWLVtwx7vYai25jQ; CS-12-A Y5CKY4ROabWI1yNRXAzB / 5XBnUMvM756tjxIMHecR / y9fqvbrEvrqbQEsEXlT1; CS-12-B 3mYi1R4HiQ38a9OPe6xs / ZjiLIMtgUyEROVXmBxU1 / udu7qdQaDxGFIJcgEicv; CS-11-C w5ue4lwMidHszP7vO4k3 / h04GkLy9oMeuGaybWZLs / 5xfk050T51cYYR8fMGE3.

## Assembled cutscenes & remaining shots

- **CS-07 (`CS-07_Something_With_Corners`)**: 21.1 s (shots A 7.04 s, B 7.04 s, C 7.04 s; hard cuts; CUE-06 score bed; 4 lines EX-CH04-S06-L01..L04). Composed to `production/cutscenes/v8/CS-07_Something_With_Corners.mp4` and encoded to `game/assets/cutscenes/CS-07_Something_With_Corners.ogv`.
- **CS-08 (`CS-08_The_Fifth_Mug`)**: 18.1 s (shots A 4.04 s, B 7.04 s, C 7.04 s; hard cuts; 4 lines EX-CH05-S01-L01..L04). Composed to `production/cutscenes/v8/CS-08_The_Fifth_Mug.mp4` and encoded to `game/assets/cutscenes/CS-08_The_Fifth_Mug.ogv`. Composed without music; a cue is now saved as `src/music/CS-08.mp3` (run 2) but CS-08.json does not reference it yet.
- **CS-09 (`CS-09_What_I_Didnt_Say`)**: 13.1 s as composed (A 8.04 s, B 5.04 s). **Spec now 19.1 s** (run 2): CS-09-C 6.00 s added after B (extend of CS-09-A, hard cuts), lines re-spaced to 0.8 / 9.0 / 12.1 / 15.9; the composed mp4 and the .ogv are stale until recomposed. No music per canon.
- **CS-10 (`CS-10_The_Name_on_the_Page`)**: spec written, 17.1 s: A 6.04 s (1080p), B 5.04 s (1080p), C 6.04 s (1080p); hard cuts; music `src/music/CS-10.mp3`; lines 3.8 (Rao, radio) / 6.6 / 11.2 / 14.0 (Rao, radio). Not composed yet.
- **CS-11 (`CS-11_The_Red_Ring`)**: spec written, 18.1 s: A 6.04 s (1080p), B 6.04 s (1080p, mirrored), C 6.00 s (720p extend of A); hard cuts; music `src/music/CS-11.mp3`; lines 4.0 / 7.6 / 11.4 / 14.5. Not composed yet.
- **CS-12 (`CS-12_The_Next_Light`)**: spec written, 15.1 s: A 5.04 s (720p retake), B 4.04 s (720p), C 6.00 s (720p extend of A); hard cuts; music `src/music/CS-12.mp3`; lines 2.9 / 5.9 / 7.4 (Amara, starts over Rafi in B) / 11.6. Not composed yet.
- All four specs checked: every line ends before the next starts and before the cutscene ends (VO lengths from `production/audio/vo_masters/`).

## Run 2 shot status (5 Nov)

| Shot | Generation | Length | Status |
|---|---|---|---|
| CS-10-A | HpeSZspNDhOEbmYY9P30 (paid 4 Nov) | 6.04 s 1080p | Accepted |
| CS-10-B | uIa5D2LOoDKQJxMILAPo | 5.04 s 1080p | Accepted (Ferreira grey only at the temple, portrait still) |
| CS-10-C | PEcGXzBdFpAYrTnBC2Gc (paid 4 Nov) | 6.04 s 1080p | Accepted |
| CS-11-A | 5xcyfG9s7XIJEZiXV9HC (paid 4 Nov) | 6.04 s 1080p | Accepted |
| CS-11-B | 2WdEOWLVtwx7vYai25jQ | 6.04 s 1080p | Accepted, mirrored in post (Mei's flag was on her right sleeve); `masters/CS-11-B.mp4` is the unmirrored original, `src/shots/CS-11-B.mp4` the mirrored one |
| CS-11-C | 5xfk050T51cYYR8fMGE3 (extend of CS-11-A) | 6.00 s 720p | Accepted, continues A's last frame exactly |
| CS-12-A take 1 | y9fqvbrEvrqbQEsEXlT1 | 5.04 s 1080p | Rejected: the white hand light turns into a black torch as Kai grabs it (deleted locally; still on the flow) |
| CS-12-A v2 | pf0dE49ecszd6rgRV2kf | 5.04 s 720p | Accepted: hand light stays white on the chest strap |
| CS-12-B | udu7qdQaDxGFIJcgEicv | 4.04 s 720p | Accepted; Kai's hand light reads dark grey in the shadowed foreground (as in its start frame), a small mismatch with the white light on his chest in A |
| CS-12-C | lHTuy9wLvWJqlxtp3HgK (extend of CS-12-A v2) | 6.00 s 720p | Accepted, borderline: Kai pulls one breaker down, lamps stay green, hand light stays white; Amara rests her hand on the panel instead of pointing, and the fourth breaker loses its handle by the end (small, dim) |
| CS-09-C | MM7UCZ1QDXvejDNh8rEB (extend of CS-09-A) | 6.00 s 720p | Accepted, continues A's last frame; added to CS-09.json |

Frames saved to `masters/frames/B/`: 10B_edit.png (already there), 11B_v2.png, 12A_edit.png, 12B_edit.png. Music picks (listen-free, by prompt and loudness shape; the other take stays on the flow): CS-08 aBFddtDaO8UdHURdS99i (not iIfBbU6ULszgu9q9PRiX), CS-10 p5KfFMIXSJhcmfNqY6vu (not 9cAoNve4pXoqaiIoeeZk), CS-11 lVrXAkbmbMx8Lrwa05eB (not GuTGo8jIcLwcfrImUA92), CS-12 hZRVMu2B1dMCAveeAxQd (not xkTlzUwthmhGMuiQC9f8). Generation log for this run: `production/ai_log_parts/cutscenes_B2.md`.

Remaining for lane B: compose CS-09 (recompose), CS-10, CS-11, CS-12 with compose_cutscene.py and encode the .ogv files; decide whether CS-08.json gets `"music": "music/CS-08.mp3"` and is recomposed; set status and elevenlabs_ids in shots.csv; merge `ai_log_parts/cutscenes_B2.md` into AI_PROMPT_LOG.md; listen to the four music picks.
