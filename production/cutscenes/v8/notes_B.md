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

## Assembled cutscenes & remaining shots

- **CS-07 (`CS-07_Something_With_Corners`)**: 21.1 s (shots A 7.04 s, B 7.04 s, C 7.04 s; hard cuts; CUE-06 score bed; 4 lines EX-CH04-S06-L01..L04). Composed to `production/cutscenes/v8/CS-07_Something_With_Corners.mp4` and encoded to `game/assets/cutscenes/CS-07_Something_With_Corners.ogv`.
- **CS-08 (`CS-08_The_Fifth_Mug`)**: 18.1 s (shots A 4.04 s, B 7.04 s, C 7.04 s; hard cuts; 4 lines EX-CH05-S01-L01..L04). Composed to `production/cutscenes/v8/CS-08_The_Fifth_Mug.mp4` and encoded to `game/assets/cutscenes/CS-08_The_Fifth_Mug.ogv`.
- **CS-09 (`CS-09_What_I_Didnt_Say`)**: 13.1 s (shots A 8.04 s, B 5.04 s; hard cut; no music per canon; 4 lines EX-CH05-S05-L01..L04). Composed to `production/cutscenes/v8/CS-09_What_I_Didnt_Say.mp4` and encoded to `game/assets/cutscenes/CS-09_What_I_Didnt_Say.ogv`.
- **CS-10, CS-11, CS-12**: Start frames (including edits) and music cues generated on flow `VuwkAWRO7pmMn1jfcAhB` (frames saved in `production/cutscenes/masters/frames/B/`); CS-10-A, CS-10-C and CS-11-A video nodes were triggered right before the session limit; CS-10-B, CS-11-B/C and CS-12-A/B/C video nodes remain to be run and pulled from the flow.

## Pending on the flow (connector dropped 4 Nov, resume here)

Real running total **506,588 / 760,000**. Generated but not yet downloaded or reviewed:
- CS-10-A video: node yomplA8DpMsd2EAeGRBX, session qRenPlLv15OBbIc9oWPB, gen HpeSZspNDhOEbmYY9P30 (6 s)
- CS-10-C video: node AZoj6Fqp23X5UAVB2Rtt, session 68jvAVdxwOSM5pr1kYox, gen PEcGXzBdFpAYrTnBC2Gc (6 s)
- CS-11-A video: node 7AhNKeDO389eGxTt4UNU, session LjucMVgfL0lCAVsR34Fu, gen 5xcyfG9s7XIJEZiXV9HC (6 s)
- Frames to review: CS-10-B edit gen ajbUj9FUoRKcVHe4Dv60 (node K8asQwy3Bz7UN7k08lNZ); CS-12-A edit gen gUBoVcCt2JYO9g6MmXRd (node n5yGUCJq0oeJZ9Rr8Oqr); CS-12-B edit gen ZjhVsqeDYEexh1q2qr2O (node 4XrGM9t1OQeHqJdDS8GV); CS-11-B v2 gen 4DyeiutNYukkXyUGfw3V (node OR9KRP6mRpv44nJQxioI)
- Music (2 variations each, never pulled): CS-08 node 6l78uVzWg0ODtnXTRMJ3, CS-10 on60dS1TtAxDG9QdNKiq, CS-11 LhOa1RBz4D5pEhdIGEhc, CS-12 l45JdOSwWIxm2GACffAH (CS-07 node QijDcY3PfeveQKj0eQ64 already used)

Still to run (planned, ~200 k): CS-10-B 5 s from the CS-10-B edit; CS-11-B 6 s from CS-11-B v2; CS-11-C 6 s chained from the last frame of CS-11-A; CS-12-A 5 s from the CS-12-A edit; CS-12-B 4 s from the CS-12-B edit; CS-12-C 6 s chained from the last frame of CS-12-A. Optional if budget remains: CS-09-C 6 s chained from the last frame of CS-09-A (Ferreira answers, Kai leans in), which would give CS-09 room to breathe (it is 13.1 s now with lines nearly back to back).

Planned line timing (hard cuts): CS-10 (A 6 / B 5 / C 6): Rao L01 3.8 (radio), Ferreira L02 6.6, Mei L03 11.3, Rao L04 14.2 (radio). CS-11 (A 6 / B 6 / C 6): Mei L01 4.0, Amara L02 7.7, Kai L03 11.4, Rafi L04 14.5. CS-12 (A 5 / B 4 / C 6): Kai L01 3.8, Rafi L02 6.0, Amara L03 7.6, Kai L04 11.1.

Video prompts used so far are on each video node; motion-only prompts for the remaining shots are drafted in this agent's run log (CS-11-C: Kai turns his head to Rafi; Rafi switches on a separate small blank side panel beside the main monitor so the diagram stays apart from the camera image. CS-12-A: the wall screen cuts to black, the amber guide light stays on, Kai's hand closes round the hand light, then he looks at the three green lamps. CS-12-B: Rafi lifts his radio and answers. CS-12-C: Amara points at the isolation section; Kai pulls one breaker lever down, checks, nods).
