# M1-52 start frame for approval: the Earth mustard field (opening beat 1)

Doc 24 §7.1 beat 1 and NR-06: a 6 s shot of a mustard field before the CS-01 cold open, so the yellow fields N. remembers (EX-CH02-S10-L03) have an image. Nothing here may imply it is Noor or Alo.

| Candidate | File | Notes |
|---|---|---|
| A, anime background art | `field_anime_v1.png` | Matches the anime cutscenes; four-petal cross flowers in the foreground, bare winter trees, mist. Has thin black letterbox bars (crop before animating). |
| B, photoreal | `field_photoreal_v1.png` | Matches the photoreal environment look; shallow depth of field, four-petal flowers, flat horizon. |

Both: 1376×768 (16:9), Tripo `image` with gemini_3_pro_image_preview, no person, no text, no logo (checked by eye).

**Sadman, please answer (one line is enough):** A or B, or what to change. After approval: animate 6 s of wind through the field (Veo), generate SFX_EARTH_FIELD_MORNING (wind, distant birds) for `production/audio/sfx_list.csv` with the caption [wind and birds], and put the shot before the M1-51 exterior with a hard cut, matching the field's yellow to the battery band.

**Approved 6 Nov 2026 by Sadman, in chat: "A, anime".** The start frame is `field_anime_v1_start_frame.png` (candidate A with the letterbox bars cropped, 1920×1080).

**Done 6 Nov 2026 (M1-52):** animated in Veo 3.1 Quality (take 1 of two), yellows graded to the battery band's
gold, and placed before the Moon exterior with a hard cut: `production/cutscenes/v8/src/shots/CS-01-F.mp4`, in
`game/assets/cutscenes/CS-01_Arrival.ogv`. Details: `production/cutscenes/v8/notes_CS-01_cold_open.md`.
