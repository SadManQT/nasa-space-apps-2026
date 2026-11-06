# M4-03: the chosen D13 dedication on CS-18's closing black (6 Nov 2026)

Sadman/night-claude2 (Claude Opus 5.5 night shift). Code and data only. No AI generation, network or credits, and no new audio.

## What the player sees

Doc 24 §7.7 beat 3 says: "Black. If the player chose 'For the gardens we leave for others' (D13), those words sit small at the bottom of the black for two seconds." The sound for that beat is silence.

| Save (`story_log.choices["EX-CH08-S12-CHOICE"]`) | CS-18 (8.0 s film) |
|---|---|
| `EX-CH08-S12-OPT02` "For the gardens we leave for others" | The film plays as before. At **7.0 s**, when the picture is fully black, the catalog label fades in (0.4 s), small and centred at the bottom of the black. It stays through the film's end at 8.0 s. The player then holds the **silent black for 1 s** and the words fade out by **9.0 s**, when the player closes. |
| `EX-CH08-S12-OPT01` or no D13 choice | Nothing is drawn. The film ends at 8.0 s, as it did before this task. |

- **The words** are read at runtime from `campaign_catalog.json` (scene EX-CH08-S12, choice option OPT02, `label`). They are never typed into code or the manifest. The test compares them with the catalog file read independently and with the canon text.
- **The style** follows UiDesign: the `body` type token (14 px on a 720p canvas, 20 px at 1080p), the `ivory` colour on pure black, and the 64 px (1080p) safe margin from the bottom of the film's 16:9 box. That places the words in the burned captions' band, but smaller. Large text scales them 150%. With reduced motion they cut in and out instead of fading. Pause (Space, P, Start) also pauses the hold. Hold-to-skip works throughout. The close result reports the words only if they were actually on screen.
- **The film's missing-file fallback** (the text card) ends with the same words when OPT02 was chosen.
- **Audio:** no new sound. During the hold the campaign stays in cinematic mode, so music, beds and voice stay held. The extra second is silent, matching 7–8 s, and the credits loop starts only when the player closes.

## Decision for Sadman: words from 7.0 s with a 1 s hold (chosen) or from 6.0 s with no hold

The film has only 1 s of black: the picture fades from 6 to 7 s, then it is black and silent from 7 to 8 s. Two seconds of words fit only one of two ways:

1. **Chosen: 7.0 to 9.0 s.** The words appear only on full black, as §7.7 asks ("sit small at the bottom of the black"), and the player holds the silent black for one second after the film ends. The cost is that a player who chose OPT02 sees CS-18 run 9 s instead of 8 s.
2. **Not chosen: 6.0 to 8.0 s.** This needs no hold, but for its first second the words sit over the fading drawer and lamp picture, which §7.7 does not ask for. It also competes with the last image of the mystery.

To switch, edit `choice_card.show_at_s` and `hide_at_s` on CS-18 in `game/resources/campaign/content/presentation_media.json` (no code change). With 6.0 and 8.0 the player never holds, because the film's end reaches `hide_at_s`.

## How it is built

- `game/resources/campaign/content/presentation_media.json`, CS-18: a new hand-authored `choice_card` key holds the choice and option ids, `show_at_s` 7.0, `hide_at_s` 9.0, `fade_s` 0.4, the type token and the colour. `build_presentation_media.py` keeps per-cutscene design keys (its docstring now names `choice_card`), and `--check` still reports "presentation_media.json is current".
- `game/scripts/cutscenes/cutscene_runtime.gd`: every plan carries `choice_card`, with its `text` resolved from the catalog option label. `choice_card(cutscene_id)` is public. A cutscene without the key gets `{}`.
- `game/scripts/cutscenes/cutscene_player.gd`: at `play()` the player reads the save's story log once and arms the card only if the recorded option matches. It reads the log, and never writes it, through `snapshot_source` or, unset, the `director` of the node it was added to (the campaign). The film clock continues through the hold: Theora resets `stream_position` to 0 at the end, so the player keeps the film's own time. `card_alpha()` is a pure function of film time.
- The campaign code is unchanged. `Chapter1Campaign` already adds the player as its child and has a `director`, and CS-18 is already queued on `campaign_complete`.

## What it depends on (other owners' open tasks)

- **D13 cannot be recorded in play yet.** `Chapter1Campaign.handle_ui_command` refuses `record_choice` outside Chapter 1, and the decision panel data is built only for Chapter 1. **M3-8M** (Atik: "record decisions per §5 with the story_log verbs from M1-47") opens D13 at EX-CH08-S12. Once it lands, this card shows with no further change. The test proves that path with the real `Chapter1Campaign` node and a real `CampaignDirector` save that passes the save validator.
- **Credits before CS-18:** today CS-18 plays right at campaign completion, and the credits music starts when it closes. The credits screen with the "post-credits CS-18 still" is **M3-90** (Ramim). The dedication logic does not depend on that order.

## Verification

- `game/tools/test_cutscene_choice_card.gd` (new suite, 47 checks). It reads the data from the catalog, checks the ids against the save validator and checks the alpha curve, including reduced motion. Inside the real `Chapter1Campaign` node, OPT02, OPT01 and no choice are each decided by the campaign's director. Skip and the text fallback are covered. Then four players play the real CS-18 OGV at once:
  - OPT02: words first at 7.009 s, fully shown at 7.5 s and 8.5 s, last at 8.993 s; film ended at 8.0 s; closed at 8.98 s after a 0.99 s hold; 14 px, centred, bottom at 677 px of 720.
  - OPT01 and no choice: nothing drawn; closed at 7.98 s and 7.99 s.
  - OPT02, paused 0.5 s in the hold, with large text: hold 1.51 s; 20 px.
- Window captures through the real player at 1280x720, window on top (`M4-03_capture.sh`, which runs `game/tools/capture_m4_03.gd`; log in `M4-03_capture_output.txt`):
  - `M4-03_dedication_opt02_7.5s.png`: the words on the film's black at 7.528 s.
  - `M4-03_dedication_opt02_8.5s.png`: the same words in the held black after the film, at 8.517 s.
  - `M4-03_dedication_opt01_7.5s.png`: black with nothing drawn, at 7.533 s.
- `game/tools/run_tests.sh`: see `M4-03_tests.txt` (last line quoted in the board evidence).

## For Sadman

1. Agree or change the 7.0–9.0 s choice above (one data edit).
2. Watch the two OPT02 shots at gameplay size. The words are deliberately small (UiDesign body); if you want them quieter, `colour` can be `muted`.
