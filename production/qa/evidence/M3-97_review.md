# M3-97 fix-round evidence — 5 November 2026

Ported only this task from `origin/night/M3-97`; no merge, commit, push, purchases or credit use. The current board's M3-94 approval and M3-94R split override the parked branch's obsolete blocker and text alternatives.

- `M3-97_port_provenance.txt`: all three restored post-composite shot binaries match the parked branch's LFS SHA-256 values.
- `M3-97_staging_checks.txt`: exact canonical dialogue, both round trips, cue timing, non-overlapping picture beds, full audio coverage, rendered durations, ffmpeg scdet, four-frame blink, digital silence and master-frame evidence. The verifier fails on missing/truncated audio; an earlier render exposed timestamp-less delayed silence and was corrected before handoff.
- `M3-97_composer_compatibility.txt`: current CS-01 video filters compile identically before/after the shared composer port; trims, ramps, zooms, custom dissolves, sound captions, slates and title remain intact. This is a dry-run comparison, not a new CS-01 render.
- `M3-97_tests.txt`: required full `game/tools/run_tests.sh` transcript; last line: **34/34 suites passed**, including 537/537 performance checks.
- `M3-97_capture_preflight.txt`: capture script syntax/parse check, Theora remux durations, and PTS-based image sampling through the sparse black hold.
- `M3-97_CS15_*.png`, `M3-97_CS17_*.png`, `M3-97_CS18_*.png`: reviewed master-frame evidence; the blink strip shows frames 89–96 around the four changed frames 91–94.

Visual review against ART_BIBLE §2: lunar windows show black sky; Dhaka has no Moon; plants remain in the pressurised garden, have four-petal mustard flowers and no faces; English labels/captions, no NASA logos. Sound beds belong to the pressurised cabin/habitat and Earth pictures. The existing campaign _play_next_cutscene() calls _set_cinematic(true), and CampaignAudioDirector.set_cinematic() holds every campaign stream, so the film’s silence is not covered by a second scene bed or score. No exterior airborne sound, new mission value, founder/working-stock count or canon wording was introduced.

The pending approved Rao/Noor lines are captions, not synthetic replacement voices. `SFX_DHAKA_ROOFTOP_MORNING` and `SFX_INVENTORY_LAMP_TICK` retain silent slots. M3-94R owns all four recordings; it does not block this task (current board note).

Run `production/qa/evidence/M3-97_capture.sh` outside the sandbox before review. `godot_gated` explicitly refuses windowed calls in the seatbelt sandbox. The script encodes all three reviewed masters into runtime OGVs, removes Movie Maker's extra terminal frame, validates exact 24 fps durations and runtime/master image parity, then takes ten screenshots through the real CampaignCutscenePlayer with the window on top. It requires the printed `M3-97 CAPTURE RESULT: PASS` and `M3-97 CAPTURE: PASS`, rejects parse failures, and saves `M3-97_capture_output.txt` plus `M3-97_*_ingame_*.png`. The current runtime films must be replaced by this script before judging the new timing/captions; master-frame evidence does not claim windowed playback.

After capture: Sadman should listen to the CUE-11 entrance and picture-bed levels, inspect Tara's card and the five names at gameplay resolution, and run M3-94R in an ElevenLabs-connected session when ready. No new approval is required to run the capture script.

Minimal integration paths outside the task's owns list: `production/tools/compose_cutscene.py` (reuse the existing compositor), `game/resources/campaign/content/presentation_media.json` (generated caption cue timings), `game/tools/capture_m3_97.gd` (actual player capture), the required board/handbook and QA evidence. Existing scene_enter/campaign_complete bindings and gameplay predicates are preserved.
