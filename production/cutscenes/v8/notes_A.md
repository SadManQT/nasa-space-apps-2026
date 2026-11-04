# Cutscenes A — M1-25 remakes and CS-04, CS-05, CS-06 (4 Nov 2026)

ElevenLabs flow: `ZMiLQHaaynTExOonJLVV` ("Last Light Academy — Cutscenes A (M1-25, CS-04..06)").
Credit cap for this lane: 520,000. Prices from `estimate_only` before each run.

Measured prices: Seedance 2.5 1080p = 6,265.4 credits/s (12 s = 75,185); 720p = 2,800.9 credits/s (12 s = 33,611).

## Reference nodes on the flow

| Node | Content |
|---|---|
| J4TT9EHHRJDlalUhI7nA | CS-02-C first frame (v7 shot, 1280x720) |
| yjp9p7zRgBaSuldca4bV | CS-03-B first frame |
| K0d3gYYxDjViQvxvvcmp | CS-03-C first frame |
| otedz94DWKnw8mvSp6la | Kai v8 sheet |
| htKiBspdcEBjj5nACLVX | Amara v8 sheet |
| cTtgUqm7EHmfHxISaKYF | Mei v8 sheet |
| Gvd3Goo5tUkFZI8IgTkJ | Rafi v8 sheet |
| Ag0ibe0l2X2fvFXq283j | style_v7/A1.png |
| tadqZf5FCVqB6YDerTQ4 | v7 commons frame (CS-01-C at 1 s) |
| sadaJfKr6jNuyAasWEYA | concept/plants/zero_seedling_tray.png |
| vNctGUCUQAtOdbiz15si | concept/plants/alo_pods.png |

## Credit ledger

| Step | Credits | Running total |
|---|---|---|
| M1-25 videos CS-02-C, CS-03-B, CS-03-C (1080p, 12 s each) | 225,555.6 | 225,555.6 |
| CS-04-A start frame take 1 (rejected) | 3,654.2 | 229,209.8 |
| CS-04-A take 2, CS-04-B, CS-04-C start frames (B, C have 6 refs: 4,872.2 each) | 13,398.7 | 242,608.5 |
| CS-03-B video v2 (720p, 12 s; v1 rejected) | 33,611.2 | 276,219.7 |
| CS-04 music, 2 takes | 930.0 | 277,149.7 |
| CS-04-A/B/C videos (720p, 6+8+12 s) | 72,824.2 | 349,973.9 |
| CS-05-A/B/C start frames (4 refs: 3,654.2 each) | 10,962.5 | 360,936.4 |
| CS-06-A/B/C start frames (3,045.2 + 4,872.2 + 4,263.2) | 12,180.6 | 373,117.0 |
| CS-05-A/B/C videos (720p, 5+8+5 s) | 50,416.8 | 423,533.8 |
| CS-06-B and CS-06-C window edits (1,827.1 each) | 3,654.2 | 427,188.0 |
| CS-05 and CS-06 music, 2 takes each (450 + 450 + 375 + 375) | 1,650.0 | 428,838.0 |
| CS-06-A/B/C videos (720p, 6+9+6 s) | 58,819.6 | 487,657.6 |
| CS-05-D video (720p, 7 s, start frame = last frame of CS-05-B) | 19,606.5 | 507,264.1 |

Spent: 507,264.1 of the 520,000 cap (12,735.9 left). Resolution: the three M1-25 shots were planned at 1080p (CS-03-B's retry ran at 720p); every new CS-04..06 shot is 720p. 1080p for all of them would have cost about 815k. compose_cutscene.py outputs 1280x720, so 720p sources lose nothing in the cut, and they match the v7 sources (1284x716).

## M1-25 remakes (start frame = first frame of the v7 push-in, extracted at 1280x720)

### CS-02-C — accepted (1920x1080, 12.04 s)
- Node 3yOo12WirqirVHa0CQDe, generation SHomeeZ4gnP5f7hbVXXx, start frame node J4TT9EHHRJDlalUhI7nA. 75,185.2 credits.
- Prompt: "Anime cel-shaded animation, continuous single take. The young man in the navy coverall lifts the glowing hand light, looks at it for a moment, then carefully seats it back into its wall bracket so it keeps glowing there as a steady guide light. He lowers his hand, breathes out, and turns toward the woman in the cyan-tabbed coverall. She steps in beside him and rests her fingertips on the glowing blue planning table; he follows her gaze down to the table and gives a small, determined nod. The camera dollies slowly back and drifts right, opening the frame to include the softly glowing planning table in the foreground. Calm, quiet resolve. The warm lamp light and the cool blue table glow stay steady. Consistent characters, no deformation, stable faces and hands, same costumes and patches throughout."
- Review: the story beat (light stays in its marked place, Kai turns to the plan). Minor: Kai's hair reads brown under the warm lamp late in the shot, and the patch on Amara's right sleeve changes from the mission patch to a flag after she turns. Copied over v7/src/shots/CS-02-C.mp4.

### CS-03-B — v1 rejected, v2 accepted (1280x720, 12.04 s)
- v1: node tu8Ie5PR1pLKgdrDGBsV, generation Sl9wKVA2TU4w6P8W7DMI, 1080p, 75,185.2. Rejected: the opened shutter showed a golden, cloud-banded Earth-like sky (no golden sky through windows), and the coveralls washed to grey.
- v2: node gVPshANbCTpcM3H26EWb, generation KNHGv6X5ebvs3fXf26Vu, 720p, 33,611.2, start frame node yjp9p7zRgBaSuldca4bV. Prompt: "Anime cel-shaded animation, continuous single take, locked colour palette. The young woman in the olive apron glances from the gauges to her friends, then firmly turns the round dial. Beside her, the tall metal shutter rolls slowly upward, and the opening behind it fills with intense flat white sunlight, so bright it reads as a clean glowing white panel with no detail inside. A soft band of white-gold light slides across the wall and onto all four faces. The four friends lift their eyes toward the light: she lowers her hand and steps back, the young man behind her squeezes his friend's shoulder, the tall bearded man breathes out and smiles. The camera dollies slowly left toward the opening. Everyone's coveralls stay deep navy blue, the young man's hair stays jet black, every colour stays exactly as in the first frame; only the light on their faces warms. Hopeful, quiet relief. Consistent characters, no deformation, stable faces and hands, same costumes and patches throughout."
- Review: the opening is a featureless white panel (no sky), light falls across the faces, Mei's dial turn sits under her line. The coveralls still lighten in the bright light but stay blue. Copied over v7/src/shots/CS-03-B.mp4.

### CS-03-C — accepted (1920x1080, 12.04 s)
- Node 5hTymIjdOwo8xjeKpy3x, generation spiPJmodHN2X3WK7s1Db, start frame node K0d3gYYxDjViQvxvvcmp. 75,185.2.
- Prompt: "Anime cel-shaded animation, macro, continuous single take. Inside the clear sealed growth chamber, the warm golden light grows slowly stronger and sweeps across the young mustard plant. The topmost yellow flower slowly unfurls its four petals until it is fully open, and the small buds beside it swell slightly. The lobed leaves sway very gently in the chamber's soft air circulation. The camera makes a slow, smooth half-orbit to the right around the chamber while craning gently upward, keeping the open flower centred, and the background bokeh shifts with the move. The blank white plant tag stays plain and unmarked. The plant has no eyes and no face, only natural stem, leaves and four-petal flowers. Tender, hopeful. Consistent plant shape, no deformation, crisp clean lines throughout."
- Review: no face, purple stem, four-petal flowers, tag blank, push-in with a slight orbit. Note: by the end four or five flowers are open, not one. Copied over v7/src/shots/CS-03-C.mp4.

## Start frames (Nano Banana Pro gemini-3-pro-image, 16:9, 2K, one take each)

References wired: style_v7/A1 (Ag0ibe0l2X2fvFXq283j) on every frame, plus the v8 sheets named below; CS-04 and CS-05-C also use the v7 commons frame (tadqZf5FCVqB6YDerTQ4).

| Shot | Node | Generation | Refs | Credits | Result |
|---|---|---|---|---|---|
| CS-04-A take 1 | d3eRUq0si8Z3oifdWYEX | dKNXzGBPkW0tQp7zJM1n | commons, A1, Rafi, Kai | 3,654.2 | Rejected: the mug was half transparent, Rafi's vest had no reflective bands and no radio |
| CS-04-A take 2 | d3eRUq0si8Z3oifdWYEX | HTkDFZ20m8f3Tjbnxn9o | same | 3,654.2 | Accepted |
| CS-04-B | hOqwCLbJMaO91CLQCczh | 0bGXQicqRWmgzSWBEYCd | commons, A1, Rafi, Kai, Mei, Amara | 4,872.2 | Accepted |
| CS-04-C | OqasZOjb6dhOlXZRdUwp | ui0LTgW2UhbDe9DLYlos | same | 4,872.2 | Accepted |
| CS-05-A | FlSJGV7MqlWiSsJffLHD | mk3ufgvJC4LAwwTifw91 | A1, Mei, Rafi, seedling tray | 3,654.2 | Accepted. EVA suits designed in the prompt (no approved anime suit sheet exists); see flags |
| CS-05-B | WXrFUbHsGwHr19UwJ9fz | U1wBSjZ0U2FgXNycvdZe | same | 3,654.2 | Accepted |
| CS-05-C | KlNYYqK8uS1VDlbTQSGR | XBiuBFvAMLVwytQhLt57 | A1, Amara, Kai, commons | 3,654.2 | Accepted |
| CS-05-D | LZVbcx2dtfbhUeYLhsN0 (upload) | asset UQ9842fg3lnzbybub1hg | last frame of CS-05-B | 0 | Chained start frame |
| CS-06-A | MXolfbs8CZoD78x4Wt3w | N4okd6JEcZRPXjIDh19p | A1, Mei, alo_pods | 3,045.2 | Accepted |
| CS-06-B | QumKlodKk3we4UufrjAD | Mr7oavIpejrhnI9efUbF | A1, Mei, Amara, Kai, Rafi, alo_pods | 4,872.2 | Fixed by edit: window showed stars over a lit ridge |
| CS-06-B edit | zsb8OjQ7xzZdc3mvthSb | yGggLqacwvlv63zGa8CQ | the take above | 1,827.1 | Accepted: black sky, ridge in shadow |
| CS-06-C | hpYjqv1GZZy3v1fRmuuj | FpbcJMbwLrxeDUPWWG6a | A1, Mei, Amara, Kai, Rafi | 4,263.2 | Fixed by edit: Earth high in a starry window (wrong for the south pole) |
| CS-06-C edit | iN4HsV1Gm6rS3r2lFCWD | kcOAazJgOwmCQylRBXAk | the take above | 1,827.1 | Accepted: black windows, no Earth |

The full start-frame prompts are stored on each node. Each one lists what every reference supplies, the scene, adult proportions, flag on the LEFT shoulder with the mission patch on the right, and "nothing in the frame carries any writing; no logos".

## New shots (Seedance 2.5, 720p, 16:9, no audio)

| Shot | Node | Generation | s | Credits | Status |
|---|---|---|---|---|---|
| CS-04-A | Hq3CuJDqIlXLLdd4w51I | 9joZYLvTkf9YyvwMro6K | 6 | 16,805.6 | Accepted |
| CS-04-B | 8JObD8o6tgmoVjwubjbA | rdVIdRapj9OvsaVec5kq | 8 | 22,407.5 | Accepted |
| CS-04-C | WNUknG1wVzmPvz1qLhLK | pTAUzdaTRbJPtZvOWt78 | 12 | 33,611.2 | Accepted with a note |
| CS-05-A | uLmX9y9ABOC0tPOt3GTI | mRDoup31GqasD8Fh0Fs7 | 5 | 14,004.7 | Accepted with a note |
| CS-05-B | ve8lEcprbwXSAUl9Ekoc | ZsUTeEwxaP8uPWlYBRzV | 8 | 22,407.5 | Accepted |
| CS-05-C | pqHIebQWeMJGiQ5RumVy | LcpOhCcSx62QGYIDfCZ7 | 5 | 14,004.7 | Accepted |
| CS-05-D | 1xmFoZSM0lS4i0XSGosa | JvgWHOOpp2Uy7EbjEEQo | 7 | 19,606.5 | Accepted (1286x716) |
| CS-06-A | hBoAngBjBhUpMxfVQYR2 | Lc5SVjrgRdiCM5c9AodN | 6 | 16,805.6 | Accepted |
| CS-06-B | gztt2SFjRnNTspRCG4vW | qL68rqYXjeRuAu3xgepv | 9 | 25,208.4 | Accepted with a note |
| CS-06-C | FJ7vIO4efqNkoSS093kK | mrIfKLlcirgHCEbtbleQ | 6 | 16,805.6 | Accepted with a note |

Video prompts (exact):
- CS-04-A: "Anime cel-shaded animation, continuous single take. The room starts to shake gently from below. The white mug trembles and rattles in tiny hops on the table, the rings on the tea surface grow and slosh, and the mug stays on the table the whole time. The camera shudders slightly and racks focus from the mug to the bearded man behind it: he lifts his head from the floor, looks quickly around the room, and steps back from the table with one hand raised to the others. The young man beside him turns toward him, alert. The wall lamps sway a little. Controlled tension, no panic. Consistent characters, no deformation, stable faces and hands, same costumes and patches throughout."
- CS-04-B: "Anime cel-shaded animation, continuous single take. The room shakes gently and steadily. The three crew walk quickly but calmly into the brace bay: the young man with the cable steps in first, the short young woman in the apron follows, the tall young woman with the high bun comes last. The bearded man waves them in with his outstretched hand, then grips the rail; each of them grabs a grab rail and bends their knees, bracing side by side. The mugs on the table rattle in place, the lamp light flickers slightly. The camera pans right with them, slightly handheld. Everyone moves with normal weight and steady footing. Consistent characters, no deformation, stable faces and hands, same costumes and patches throughout."
- CS-04-C: "Anime cel-shaded animation, continuous single take. The four hold the rail as the shaking slowly eases and stops. The bearded man looks along the line at each friend in turn, counting them. The young man next to him turns his head and points at the crooked service cover on the wall. The short young woman glances back over her shoulder, then faces forward again with a firm nod. The tall young woman watches the wall panel: the second round lamp from the top changes from green to glowing red while the others stay green; she lets go of the rail, draws the tablet from her thigh holster and frowns at it. The camera pushes in slowly and drifts right toward her and the panel. Calm, focused. Consistent characters, no deformation, stable faces and hands, same costumes and patches throughout."
- CS-05-A: "Anime cel-shaded animation, continuous single take. The two suited crew step slowly and carefully forward out of the glowing hatch into the cold dark room, walking with steady normal weight. The short woman in front turns her helmet toward the frosted seedling trays on the shelves, and the white pools of her helmet lamps slide across the frost and the tiny seedlings; the tall man follows one step behind and glances back at the hatch. The camera dollies slowly backward ahead of them. The frost and seedlings stay perfectly still; the air stays clear. Quiet, respectful. Consistent characters, no deformation, stable faces behind the visors, same suits and patches throughout."
- CS-05-B: "Anime cel-shaded animation, continuous single take. The kneeling woman leans a little closer to the frozen seedlings, her gloved hand hovering just above the tray without touching it. She studies the tiny curled seed leaves, lifts her eyes to the faded growth chart on the wall, then looks back down with quiet understanding and slowly draws her hand back to her knee. Behind her, the tall man raises the camera to his visor and holds it steady, recording. The camera pushes in slowly toward her face. The seedlings stay completely still and untouched, frost unchanged. Quiet, sad, respectful. Consistent characters, no deformation, stable faces behind the visors, same suits and patches throughout."
- CS-05-C: "Anime cel-shaded animation, continuous single take. The seated woman with the headset studies the monitor, lightly touches the microphone at her cheek and speaks, giving a small confirming nod. The young man beside her lifts the radio a little closer, then turns his head to the round viewing port, where the two small lamp glows drift slowly in the dark. The camera pushes in slowly between them. Warm steady light. Consistent characters, no deformation, stable faces and hands, same costumes and patches throughout."
- CS-05-D: "Anime cel-shaded animation, continuous single take that carries straight on from the first frame. The tall man lowers the camera from his visor and speaks a few calm words. The kneeling woman gives a small nod, takes one last look at the frozen seedlings, then rises slowly to her feet, keeping her hands away from the tray. Both turn toward the right of frame and begin to walk out together with steady normal weight, their helmet lamps sliding off the tray and the chart. The camera holds, then eases back so the untouched seedling tray stays in the lower left foreground as they leave. The seedlings and frost stay perfectly still. Quiet, respectful. Consistent characters, no deformation, stable faces behind the visors, same suits and patches throughout."
- CS-06-A: "Anime cel-shaded animation, continuous single take, macro. Her fingers gently press the dry pod open along its seam; the tiny round dark seeds trickle out one after another and drop straight down into the white tray, bouncing lightly and settling beside the others. She sets the empty pod down at the tray's edge and her hands rest still for a moment. The camera slowly racks focus from her hands to the pressed yellow petal resting against the chamber wall, then drifts gently toward it. Warm, low, quiet light. Consistent hands and costume, no deformation, the petal and tray keep their shapes."
- CS-06-B: "Anime cel-shaded animation, continuous single take. The young woman in the apron stays bowed, slowly turning the empty pod in her fingers, and speaks quietly. The tall young woman beside her rests a hand on her shoulder and answers softly. Across the bench, the young man with untidy black hair begins to rise from his stool, pauses halfway and looks at her with a gentle question; she lifts her head and meets his eyes, and he sits back down on the stool. The bearded man beside him stays still, eyes kind. The camera pushes in slowly toward the young woman in the apron. Warm low light, quiet grief and companionship. Consistent characters, no deformation, stable faces and hands, same costumes and patches throughout."
- CS-06-C: "Anime cel-shaded animation, continuous single take. With the soft brush, the young woman in the apron slides one tiny seed into an empty well, then brushes a second seed into the next well. The young man points gently to the next empty well and she gives a small nod; the tall young woman and the bearded man lean a little closer, faint warm smiles returning. The seeds stay small and round and move only where the brush pushes them. The camera cranes slowly down toward the counting tray. Warm golden light, the windows stay black. Consistent characters, no deformation, stable faces and hands, same costumes and patches throughout."

Review notes:
- CS-04-A: the tea sloshes and steams; Rafi looks down, then raises a hand to the others; Kai turns. The mug trembles only slightly.
- CS-04-B: the three walk into the bay and all four brace on the overhead rail; a mug tips over on the table (it falls under gravity, so this is acceptable).
- CS-04-C: roll-call looks, Kai points toward the cover, Mei nods, and Amara takes out her tablet as the camera pushes in. **All five panel lamps turn red, not one** (the story says one indicator turns red).
- CS-05-A: the hatch closes behind them as they enter. Frost on the lamp-lit seedlings glints bright white; it reads as frost, but check that it does not look like glowing plants.
- CS-05-B: hand hovers without touching, Rafi photographs, Mei draws her hand back. The seedlings stay unflowered (curled sprouts only).
- CS-05-D: carries on from B's last frame. Rafi lowers the camera and speaks, Mei nods, stands with her hands clear of the tray, and both walk out to the right, leaving the tray untouched in frame. The chart has silhouettes only; Rafi's face is cropped by the top of the frame.
- CS-06-B: Kai stands fully, then sits back down. **The model added its own hard cut at 8.375 s to a close-up of Mei in tears** (0.67 s before the shot ends). It is consistent with her design and lands on "Stay."
- CS-06-C: the camera cranes down into the counting tray. **The clear reserve jar looks full of seeds**, more than the 30-seed reserve.

## Music (eleven_music_v2_5, instrumental, 2 takes each, chosen by loudness shape)

| Cue | Node | Takes (generation ids) | Chosen | Credits |
|---|---|---|---|---|
| CS-04 (31 s) | 8G1dbyLLC15qwBGHZl8L | FcPBvcxtMx0p4HBu7oJX, ehRaY9rpu06gCgQhLM6G | ehRaY9rpu06gCgQhLM6G (soft fade-in, even bed; take 1 pulses hard all the way) | 930 |
| CS-05 (30 s) | a2OP0HgCVGY1T5s5MUcB | DA4bb8twMjzMSyTHbgaD, UqCAIKTnQfRygmaVnvjQ | UqCAIKTnQfRygmaVnvjQ (sparse, about -33 dB RMS) | 900 |
| CS-06 (25 s) | 5s5N67EJzRiWbqZiH50r | AYq1TGYlMpQ3h48ffNrQ, IbGcqlBs9YlUAqOYTcvE | AYq1TGYlMpQ3h48ffNrQ (piano with rests, lifts near 13 s, near silence at the end) | 750 |

Prompts: CS-04 "Instrumental anime film score cue, 31 seconds, restrained and controlled. Opens with a low, uneasy ambient synth pad and a soft, deep pulse on muted low drums. From about 6 seconds tension rises with tremolo cellos and a steady ticking pulse, urgent but calm, never frantic, no big hits. Around 17 seconds the pulse thins and a quiet, steady solo piano figure enters over warm sustained strings, settling into cautious determination, ending on a held, unresolved chord that fades." CS-05 "Instrumental anime film score cue, 30 seconds, minimal and respectful. A cold, sparse ambient pad with soft high string harmonics and slow, distant felt-piano notes with lots of space between them. Around 10 seconds a quiet low cello drone enters, sorrowful but calm. In the last 8 seconds a single warmer string chord rises softly and fades out, gentle and unresolved. Slow tempo, no percussion." CS-06 "Instrumental anime film score cue, 25 seconds, tender grief turning to quiet warmth. Slow, spacious solo felt piano playing a simple falling melody over a soft, warm string pad. Around 13 seconds gentle low strings swell underneath and the melody turns toward a hopeful major chord, then thins to a single sustained piano note and near silence in the last 5 seconds. No percussion."

The takes were chosen from loudness envelopes, not by listening. Sadman should listen once.

## Specs and timing (src/CS-04.json, CS-05.json, CS-06.json)

Line times are set from the measured VO master lengths (production/audio/vo_masters, 4 Nov).
- CS-04 The Floor Answers First: A 6.04 + B 8.04 + C 12.04, cut, cut = 26.1 s. Rafi 7.0 (in B, waving them in); Kai 14.4, Mei 17.3, Amara 20.6 (ends about 24.8) in C.
- CS-05 The Garden That Never Opened: A 5.04 + B 8.04 + C 5.04 + D 7.04, cut x3 = 25.2 s. Mei 5.6 (B); Amara (local link, radio) 13.4 (C); Rafi 18.3, Kai (local link, radio) 21.55 (D, ends about 23.8). D continues B's action from its last frame across the C cutaway.
- CS-06 Forty-Two Sounds on a Tray: A 6.04 + B 9.04 + C 6.04, dissolve, dissolve = 20.1 s. Mei 6.0, Amara 9.2, Kai 11.8 (B); Mei "Stay. Then help me count." 13.9, which lands on the close-up and runs through the dissolve into the counting shot.

## Handoff to Claude (compose step not run)

- The specs point at `../../masters/CS-0N-X.mp4`, but `production/cutscenes/masters/` and `review/` are git-ignored (.gitignore lines 30-31). The cuts will compose on this machine. Before committing, copy the shots to a tracked folder (as v7 does with `src/shots/`) or keep them through LFS.
- Check of all three specs: every path exists, the caption text matches vo_lines.csv exactly, and no lines overlap. Lengths: CS-04 26.1 s, CS-05 25.2 s, CS-06 20.1 s.
- The M1-25 shots in v7/src/shots are mixed now: CS-02-C and CS-03-C are 1920x1080, CS-03-B and the untouched shots are about 1284x716. compose scales every shot to 1280x720. The v7 cuts CS-02 and CS-03 need recomposing to pick them up; their old specs time lines against 12 s shots, and the new shots are 12.04 s.
