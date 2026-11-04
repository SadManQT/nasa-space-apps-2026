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
| CS-08-C 7 s + CS-10-A 6 s + CS-10-C 6 s + CS-11-A 6 s videos + CS-10/11/12 start frames & edits | 146,449 | 468,995 |

## Assembled cutscenes & remaining shots

- **CS-07 (`CS-07_Something_With_Corners`)**: 21.1 s (shots A 7.04 s, B 7.04 s, C 7.04 s; hard cuts; CUE-06 score bed; 4 lines EX-CH04-S06-L01..L04). Composed to `production/cutscenes/v8/CS-07_Something_With_Corners.mp4` and encoded to `game/assets/cutscenes/CS-07_Something_With_Corners.ogv`.
- **CS-08 (`CS-08_The_Fifth_Mug`)**: 18.1 s (shots A 4.04 s, B 7.04 s, C 7.04 s; hard cuts; 4 lines EX-CH05-S01-L01..L04). Composed to `production/cutscenes/v8/CS-08_The_Fifth_Mug.mp4` and encoded to `game/assets/cutscenes/CS-08_The_Fifth_Mug.ogv`.
- **CS-09 (`CS-09_What_I_Didnt_Say`)**: 13.1 s (shots A 8.04 s, B 5.04 s; hard cut; no music per canon; 4 lines EX-CH05-S05-L01..L04). Composed to `production/cutscenes/v8/CS-09_What_I_Didnt_Say.mp4` and encoded to `game/assets/cutscenes/CS-09_What_I_Didnt_Say.ogv`.
- **CS-10, CS-11, CS-12**: Start frames (including edits) and music cues generated on flow `VuwkAWRO7pmMn1jfcAhB` (frames saved in `production/cutscenes/masters/frames/B/`); CS-10-A, CS-10-C and CS-11-A video nodes were triggered right before the session limit; CS-10-B, CS-11-B/C and CS-12-A/B/C video nodes remain to be run and pulled from the flow.
