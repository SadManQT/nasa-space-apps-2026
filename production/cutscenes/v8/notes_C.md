# Cutscenes C — CS-13 to CS-18 (board M3-7C, M3-8C), 4 Nov 2026

ElevenLabs flow: `ohCLHNNmFC3WCbbqUPC3` ("Last Light Academy — Cutscenes C (CS-13..18)").
Credit cap for this lane: 820,000. Prices from `estimate_only` before each run.

Measured prices: Seedance 2.5 1080p = 6,265.4 credits/s (10 s = 62,654); Nano Banana Pro 2K = 1,218 per take; eleven_music_v2_5 45 s x 4 variations = 5,455.

Budget plan: about 116 s of 1080p video (~727k), ~14 start frames x 2 takes (~34k), 6 music cues (~10k), about 45k kept for retakes. At 1080p the cap cannot buy the handbook lengths (sum of minimums 140 s), so each cutscene is sized to carry its four lines with breathing room; hard cuts (new "transitions" option) are used where shots chain, so no time is lost to dissolves.

## Reference nodes on the flow

| Node | Content |
|---|---|
| RDfCBkQhzMkDYn3m5tMR | Kai v8 sheet |
| pVUK5HoVdIgQMJKhFCPh | Amara v8 sheet |
| NHYnBuX8R8JV42E3YZQK | Mei v8 sheet |
| 3qMVB2skANBqooGxcE3K | Rafi v8 sheet |
| cATIGaV5I2zTqtQzPgTf | Ferreira v8 sheet |
| QFqrddk8e2HwVjxHq2Sd | v7 style frame, interior (CS-01-B at 3 s) |
| p8xebk16psLWsDv2HTpE | v7 style frame, exterior (CS-01-A at 3 s) |
| YfF7h5E2J4taS6oy5KtR | v7 garden shutter frame (CS-03-B at 3 s) |
| ZagqqlSkioUeqiAee9Gi | v7 Alo with blank label (CS-03-C at 3 s) |
| 1DBvLKAbHfRu75GkkF0V | Noor present portrait (game/assets/ui/portraits) |
| C7aMeBqYrjuuCrv5lGmy | VH_Rover crop (review/contact_vehicles.png) |
| gQeyBbnvJuDlRdbFClnW | seed case concept |
| a2YY6fXxvOvx3cl8nwtT | field mustard concept (alo_bloom) |
| zoGbC9fK37y19i1ks9WB | young cotton concept |
| 8yPQCw3MmWseAyfxR1Zt | Malapert relay concept |
| NCBLnyMoTJMYX58qA9pO | survey beacon concept |

The v7 cutscene frames are used as the style reference instead of the style_v7 line-ups because the line-ups draw Ferreira fully grey.

## Shot plan

| Cutscene | Shots (s) | Joins | Length |
|---|---|---|---|
| CS-13 The Last Log | A 6, B 6, C 8 | cut, cut | 20.0 |
| CS-14 Before the Road | A 7, B 5, C 7 | cut, dissolve | 18.5 |
| CS-15 Hello, Aurora | A 5, B 9, C 5, D 8 | dissolve, cut, cut | 26.5 |
| CS-16 The Same Road Home | A 8, B 11 | fadeblack | 18.0 |
| CS-17 What We Grew | A 6, B 9, C 8, D 8 | cut, dissolve, cut | 30.5 |
| CS-18 The MARS Drawer | still | — | 6 |

## Credit ledger

| Step | Credits | Running total |
|---|---|---|
| Price probes (estimate only) | 0 | 0 |
| Start frames batch 1 (Nano Banana Pro 2K): CS-13-A, CS-14-A, CS-15-A, CS-17-A x2 takes (3 refs, 3,045 each); CS-14-C, CS-15-C, CS-16-A x1 (2,436); CS-15-B, CS-18-A x1 (1,827) | 35,323.7 | 35,323.7 |
| Music: 6 cues x 2 variations (eleven_music_v2_5, instrumental) | 4,530.0 | 39,853.7 |
| Frame edits (Nano Banana Pro): CS-13-A petal, CS-14-A Mei hair, CS-17-A Ferreira, CS-16-A night, CS-18-A drawer closed | 10,353.5 | 50,207.2 |
| Videos (Seedance 2.5 1080p): CS-14-C 7 s, CS-15-B 9 s, CS-15-C 5 s, CS-15-A 5 s | 162,901.3 | 213,108.5 |
| Frame edit (GPT Image 2.5 Sunburst): CS-14-A patches | 517.6 | 213,626.1 |
| Start frames (Sunburst, 2 takes): CS-14-B, CS-13-B, CS-16-B | 4,075.1 | 217,701.2 |

Remaining under the 820,000 cap: 602,298.8.

Notes: Nano Banana Pro charges about 609 credits per wired reference per take, so the five sheets were merged into one to-scale cast line-up (node XydOog8bQBSsGZqk7pnh). GPT Image 2.5 Sunburst edits cost about 518 credits and fixed sleeve patches that Gemini could not; use it for edits and follow-up frames. Seedance 2.5 sometimes inserts its own hard cut (CS-15-B cut at 0.333 s): add "one continuous shot, no cuts" to every video prompt and check every master with `ffmpeg -i X -vf scdet=threshold=12 -f null -`.

## Shots and frames

| Shot | Start frame (generation id, node) | Video node / generation | Status |
|---|---|---|---|
| CS-13-A | Lg4oGiU0AdaUfnJwHtUm (edit node ypRkUfy84c05q0cWZn9Q) | ZXlAC5Xpoct61Yyo4FEL, 6 s, prompt ready, NOT RUN (estimate 37,592) | to generate |
| CS-13-B | Sunburst node vyMyRYcW1QfMyzdlFBCf (gens CTGvziYvgcCoqwaEigU1, RCuKtzZLHHh0VlfFw8hX) | not created | frame to review |
| CS-13-C | plan: last frame of CS-13-A | not created | — |
| CS-14-A | QzSqeI5rufhc0QT7TD0V (Sunburst node eFYROpMnmidWhMaroKq2), accepted | not created | to generate |
| CS-14-B | Sunburst node 6zHzUv6GPllvaUnRGEpC (gens jhv3nuOAgR8UVL2I7Sxm, pFp7fleI93kBUTL2op7B) | not created | frame to review |
| CS-14-C | wXDwoM6Z6qFWBtNIcs94 (node eMipTvm7rYtUpGMyrGd3), accepted | HkCLvWr1CYKOZgDrl1KS / Z72VitHViWfybuqBAHXp (session 2776yRcvwKmnk0ua2dVl), paid | download + review |
| CS-15-A | EZ60BuvRJYgdBJvDJdxl (node bi9jH3Yq3UtFGfFTjc2Q), accepted | ta5lPaWJYAGoirahDh6H / 3R61uMAebJc5WBuGy3lo (session ZuGIYucXZV8Ly4cHF1lR), paid | download + review |
| CS-15-B | pc2igIhjLVUsXAlDRRhG (node n9F8wH3joepZAL4t8o5W), accepted | DvWusIR00FhwIfAGtwc8 / w5Qwe1AbMk4dvjoPGE1v, 9.04 s | ACCEPTED after trim: Seedance put a hard cut at 0.333 s (wide start frame, then a continuous arc from behind Noor to her face); first 0.375 s cut, master 8.67 s, 10-bit HEVC; copied to v8/src/shots/ |
| CS-15-C | 0OwA5pu0sivnnTjQmAei (node 6CCSuv73xW8shNMDwG6Q), accepted | RapXhKOVVsal8qvaGzOP / hOfxVQVC6TQv8gXJdXCo (session zEzFjvdqXhu50cSYnq4D), paid | download + review |
| CS-15-D | plan: last frame of CS-15-A | not created | — |
| CS-16-A | QZ4Hq0QLxZ85ROUjcRU2 (edit node 1ykn9Ezcz8w8UecDK8UH), accepted | 9Bin8yg396h6MYL3Fge0, 8 s, prompt ready, NOT RUN | to generate |
| CS-16-B | Sunburst node 5CKDnhUVwwkwjC3vXjzk (gens E90H1qbTlWRiTycjsOuk, 5WlzjQfgdOwLhIhDPPlI); plan an end frame (hatch open, three step in) | not created | frame to review |
| CS-17-A | LqmeFcTCVkxqVwqtaRyJ (edit node 45eoEUXUW7EcwlZtQ65b), accepted | jahEMc9Il4IBdeLiqmSS, 6 s, prompt ready, NOT RUN | to generate |
| CS-17-B | plan: start = last frame of CS-17-A, end = Sunburst edit "shutter open, white low sunlight, black sky, grey regolith" | — | — |
| CS-17-C/D | plan: petal sleeve beside blank lineage label + Ferreira line; shared photo by the cotton with Noor on a tablet | — | — |
| CS-18-A | NlTVkOw0UBCCmG7PJDwp (edit node f36Zk6w0SroWtbdGPrNO), accepted | still, composed by another session | done |

Rejected frames: CS-13-A take 2 HP9QMzl1Ml86zuU2tiel (duplicate Rafi, no Ferreira); CS-13-A take 1 tXbhDQFsIlwiLHsKigc7 used only as edit base (five-petal flower); CS-14-A take 2 pLJ6HFkQOetvFksDBUMR (duplicate Amara, no Ferreira); CS-14-A take 1 doAivqhnHwnuK1eKRoCO and Gemini edit wt9XIFkLYPX2RPKUtrMa (edit bases: Mei's hair, patches on the wrong sleeves); CS-15-A take 1 UlCvNkGj43n93vr5wwyK (full Earth); CS-16-A 9Gg7C86NhsjyK3a6oXtE (edit base: daylight-bright ground, headlight glow); CS-17-A take 2 C6NSICqZ1ySGnJ2qT93S (two Kais, no Ferreira); CS-17-A take 1 BPlPncIBoU3smURvAv5a (edit base: wrong Ferreira); CS-18-A Z2WbtgGsSKyWd9mBFAmG (edit base: drawer open).

Music nodes (2 variations each, paid, not yet downloaded): CS-13 ClVZmhJYQt2LxhdaYwuX (25 s), CS-14 q3rxkWb9t8jwaZDW5t5w (24 s), CS-15 U1wywBHGCcFUCE9lxp5W (32 s), CS-16 4yMeAiedpv4TrBidzvo8 (23 s), CS-17 PtrSFaNIHrwqzi8lhfWo (36 s), CS-18 89GvzcYfMOtIeySlSGvY (11 s). Sessions: vhdqedy4f2jxSdbtz3en, z0Uy6SSvPA3ESVJrNHFE, PtsP4OyQY70nkUVbKmub, PehATigNrD2eQadHlZTq, Kl6lRICUkiAh8Uljhhs0, zeSRxtGjwnj3iUi5ksWb, 4JIojzcDkdBD83AcItcQ, NIepYFFNYVzleZ4cSEGS, GoSSOdquhHv92TTSwRqQ, BDrwoMyiLUUslgqPvpUp, 1MpKLwWlsMDtgYOMYOH3, qVLgdLwKqHAQXzJHowEt.

Start-frame prompts and video prompts are stored verbatim on each node of the flow.

## Blocker (4 Nov, 21:45)

The ElevenLabs connector ("claude.ai ElevenLabs (2)") disconnected while this lane was resuming, so the paid CS-14-C, CS-15-A and CS-15-C videos, the Sunburst frames and the 12 music takes could not be re-linked or downloaded, and nothing further was generated. All signed links from before expired at 19:00. Resume: reconnect, call creative_get_flow_run_status with the session ids above (no new charge), intake the three videos, review the Sunburst frames, then run the prepared nodes ZXlAC5Xpoct61Yyo4FEL, 9Bin8yg396h6MYL3Fge0, jahEMc9Il4IBdeLiqmSS (estimate 125,309) after adding "one continuous shot, no cuts" to their prompts.
