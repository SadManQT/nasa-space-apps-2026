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
| Start frames batch 1: CS-13-A, CS-14-A, CS-15-A, CS-17-A x2 takes (3 refs, 3,045 each); CS-14-C, CS-15-C, CS-16-A x1 (2 refs, 2,436); CS-15-B, CS-18-A x1 (1 ref, 1,827) | 35,323.7 | 35,323.7 |

Note: Nano Banana Pro charges about 609 credits per wired reference per take, so the five sheets were merged into one to-scale cast line-up (node XydOog8bQBSsGZqk7pnh, front and side views of Kai, Amara, Mei, Rafi, Ferreira; built from turnarounds_v8/*/views).

## Shots & Assembly Status

- **CS-18 (`CS-18_The_Closed_Drawer`)**: 6.0 s post-credit still from accepted start frame `NlTVkOw0UBCCmG7PJDwp.png` (node `M4mJ2u7xW4uE38m29a1H`). Composed to `production/cutscenes/v8/CS-18_The_Closed_Drawer.mp4` and encoded to `game/assets/cutscenes/CS-18_The_Closed_Drawer.ogv`.
- **CS-15-B**: 9.04 s summit rover cabin shot (`CS-15-B.mp4`, stored in `production/cutscenes/masters/CS-15-B.mp4`).
- **CS-13..CS-17**: Start frames (including GPT Image 2.5 Sunburst edits for CS-13-B, CS-14-B, CS-16-B) and all 6 music cues (CS-13..CS-18, 2 variations each) were generated on flow `ohCLHNNmFC3WCbbqUPC3` (`production/cutscenes/masters/frames/C/`); CS-14-C, CS-15-A and CS-15-C video nodes were triggered on the flow before the session limit and can be pulled alongside the remaining Seedance shots for CS-13, CS-14-A/B, CS-15-D, CS-16 and CS-17.
