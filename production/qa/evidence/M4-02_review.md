# M4-02 — CS-18 lamp tick installed, CS-15 Dhaka bed deferred (6 Nov 2026)

Sadman/night-claude2 (Claude Opus 5.5 night shift). No AI generation, network or credits: the effect is M3-99's take.

## What changed

| Film | Change |
|---|---|
| CS-18 The Closed Drawer (8.0 s) | `SFX_INVENTORY_LAMP_TICK` is in: the `pending` key is gone from `production/cutscenes/v8/src/CS-18.json`, the master was recomposed and the runtime OGV re-encoded. The picture did not change: video packets (master) and decoded frames (OGV) hash identically before and after (`M4-02_provenance.txt`). |
| CS-15 Hello, Aurora (29.75 s) | Unchanged. M3-94R (Rao's and Noor's recordings) is still open, so the Dhaka bed keeps its `pending` key and the film will be encoded once, with the voices: board task **M4-04**. The pending note now says so. |

## The tick against the blink (doc 24 §7.7 beat 2: the lamp blinks once, `SFX_INVENTORY_LAMP_TICK`, once)

- The take's attack is 5.5 ms into the file (energy within 20 dB of its peak); at `at: 3.8` the gate's onset detector puts the click at **3.8045 s** in the master and **3.8059 s** in the runtime film, inside **frame 91**, the first of the four lit frames (91–94, decoded from the runtime film at their own timestamps), 14 ms after the lamp lights.
- One click in the whole film (onset detector over 0.9–6.9 s); its decaying ring is one event, not a double tick.
- Level: 7.8 dB over the fan bed in 100 ms windows (+3.2 dB master / +3.0 dB runtime over 400 ms), film peak −2.4 dBFS master, −3.1 dBFS runtime. The bed itself is unchanged: outside 3.8–4.2 s (the tick and its ring) old and new mixes match with a best-fit gain within ±0.03 dB and a residual of at most −67 dBFS RMS, which is AAC coding noise (`M4-02_provenance.txt`). Black tail 7–8 s: digital silence.
- Sheet: `M4-02_CS18_tick_sync.png` (frames 89–96 above the waveform of exactly those frames, plus the 8 s level envelope).

## The gate

`production/cutscenes/v8/src/verify_staging.py`:
- requires the tick installed and landing once on the first lit frame, in the master and (with `--runtime`) in the OGV, with the lit frames measured in each film's own pictures (a picture that slips a frame fails too);
- requires the Dhaka bed to go in together with the Rao and Noor recordings;
- compares every runtime film's **sound** with its master (largest 50 ms level difference 0.76–1.17 dB on matching films; the old silent CS-18 OGV was 12.7 dB off; limit 3 dB). Before, `--runtime` compared frames only, so `M3-97_capture.sh` would have kept the silent film;
- `--stale` lists runtime films whose picture or sound drifted; `M3-97_capture.sh` re-encodes only those (this run: CS-18 alone, so CS-15's and CS-17's LFS films were not churned);
- writes scdet evidence without ffmpeg's filter address, so it only changes when the cuts do.

Result: `M3-97 STAGING RESULT: PASS (masters + runtime)`, `M3-97 CAPTURE RESULT: PASS (0 failures)`, `presentation_media.json is current` (`M4-02_capture_output.txt`; the first, re-encoding run is quoted in `M4-02_provenance.txt`).

## Evidence

- `M4-02_CS18_tick_sync.png` — the sync sheet, from the runtime film.
- `M4-02_capture.sh` — reproduces everything: `M3-97_capture.sh` (re-encode if stale, parity, ten window captures through `CampaignCutscenePlayer`), then `M4-02_sync_sheet.py`.
- `M4-02_capture_output.txt`, `M4-02_provenance.txt`, `M4-02_tests.txt` (full `game/tools/run_tests.sh`).
- In-game window captures of CS-18 (`M3-97_CS18_ingame_{hold,blink,black}.png`) were retaken by this run and are byte-identical, as the picture is unchanged.

## Joins (doc 24 §2.9)

CH08 → credits → CS-18 (Fix; O, S): the sound half is done, since the tick echoes the CH01-S02/S03 blink that opened the mystery. The dedication half had no board task (M3-97's notes and the handbook named M4-01, which is the eclipse-props review), so **M4-03** now draws the chosen D13 line on CS-18's closing black at runtime: two seconds from 7.0 s, when the picture is fully black, with the black held one second past the 8 s film (the film has only 1 s of black; 6.0–8.0 s would put the words over the fade).

## For Sadman

1. Listen to CS-18 around 3.8 s: one soft relay tick with the blink, not startling over the fans.
2. Optional: a burned-in `[inventory lamp]` sound caption (CS-01 style, 3.8–5.8 s, clear of the 6 s fade) is a one-line `captions` entry. It was left out because the blink already shows the event and a caption appearing at 3.8 s would pull the eye off a 167 ms blink.
3. M3-94R: record only the three voice lines (both effects exist). Then M4-04: the 2.6 s pause decision (recommended: the Dhaka bed starts with Noor's first word at 7.64 s) and a listen. Pre-check: Noor's radio line −23.6 LUFS against the bed −38.7 LUFS (15.1 LU).

## Fix round (6 Nov 2026, Sadman/night-claude2)

The external review did not run (the reviewer returned RESOURCE_EXHAUSTED 429, a quota error), so no findings came back and nothing was changed. This round re-checked the work instead:
- `compose_cutscene.py` on a copy of `src/CS-18.json` (output in a scratch folder) rebuilds the committed master byte-identically: file sha256 `2212ed7c…`, video packets md5 `63f67dc1…`, audio md5 `7070db02…`, the same as in `M4-02_provenance.txt`.
- `verify_staging.py --stale` lists no films; `verify_staging.py --runtime` gives `M3-97 STAGING RESULT: PASS (masters + runtime)` (tick at 3.8045 s master / 3.8059 s runtime, on blink frame 91).
- `build_presentation_media.py --check`: `presentation_media.json is current`.
- `game/tools/run_tests.sh` (godot_gated): `42/42 suites passed` (`M4-02_tests.txt` refreshed).

## Fix round 2 (6 Nov 2026, Sadman/night-claude2)

The parked work stopped because every account hit its usage limit, so the external review never ran. The night-shift reset the board, so this round claimed M4-02 again and re-filed M4-03, M4-04 and the M3-94R note. An independent Claude subagent then reviewed the diff read-only and returned FIX. Fixed:
1. **The gate measured the blink only in the source shot.** So the runtime "on blink frame 91" check really only checked the sound. `verify_staging.py` now decodes each film's own frames 86–100 at their stored timestamps (`film_frames`, `lamp_rise`, `lit_frames`, shared with `M4-02_sync_sheet.py`). It checks that the master and the OGV each light frames 91–94 like the blink shot, and that the tick lands on that film's own first lit frame. Mutation check: the master shifted by one frame measures [92, 93, 94, 95] and would fail.
2. **`notes_C.md` said `M3-97_capture.sh` re-encodes all three OGVs.** It now says the script re-encodes only the `--stale` films, after the masters pass their own checks.
3. **`M3-97_review.md` and M3-97's board evidence still named M4-01 for the D13 overlay.** Both now carry a dated correction to M4-03.

The reviewer's minor notes, also done:
- runtime/master **sound-length parity**: at most two 50 ms windows apart (159/160, 594/595, 613/613).
- The Dhaka bed and the lamp tick are found **by file name**, not by list position.
- The tick window is a **fixed 4,800 samples**.
- The sync sheet **asserts before it draws**.
- `M3-97_capture.sh` runs the **masters-only gate before it replaces any OGV**.
- **Unbacked numbers are measured or corrected** in `M4-02_provenance.txt`: 5.5 ms attack; 12.7 dB for the old silent OGV; "+3.5 dB momentary" was not reproducible and is now +3.2 dB master / +3.0 dB runtime over 400 ms; the bed is unchanged outside 3.8–4.2 s within ±0.03 dB, with a residual of at most −67 dBFS.
- **M4-03's timing:** doc 24 §7.7 beat 3 asks for two seconds of words on the black, and the film has one, so the words show 7.0–9.0 s with the black held one second past the film. M4-03's prompt names the 6.0 s alternative for Sadman.
- **M4-04's prompt** names the four gate checks the install changes.

Also found this round: this slot was checked out without LFS smudge. The CS-15 and CS-17 masters were pointers, so `--stale` called both films stale, and the capture script would then have tried to re-encode them from pointer files. `require_media` now checks the masters, the CS-18-A blink shot and (in `--stale`) the runtime films, and stops with a fetch hint on a pointer. The needed files were smudged in place with `git cat-file --filters`, which leaves no content diff.

Re-verified:
- `compose_cutscene.py` rebuilds the CS-18 master byte-identically (sha256 `2212ed7c…`).
- The OGV is still `64d46ab8…`.
- `bash production/qa/evidence/M4-02_capture.sh` printed `M3-97 STAGING RESULT: PASS (masters + runtime)`, `M3-97 CAPTURE RESULT: PASS (0 failures)` and `M4-02 CAPTURE: PASS`. No film was re-encoded, and the ten in-game window captures are byte-identical to the accepted ones.
- `build_presentation_media.py --check` reports the media file is current.
- `run_tests.sh` gave `42/42 suites passed` (`M4-02_tests.txt`), run after the last game-side state. Only Python gate code and documents changed after it, and the runner does not use them.

The burned-in `[inventory lamp]` caption stays out. The reviewer agreed it is not a defect: the blink is the event, M1-61's house style captions only informative sounds, and CS-15, CS-17 and CS-18 consistently carry no sound captions. It remains Sadman's optional call, at 3.8–5.8 s.
