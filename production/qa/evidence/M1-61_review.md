# M1-61 — sound captions

6 November 2026 · Sadman/night-codex · OpenAI Codex / GPT-6 (night shift).

Sound captions use the existing UiDesign dark-glass panel, ivory text, light edge and 12 px corners. Short cues size to their text; simultaneous cues wrap within the left third. The panel sits at the bottom safe margin while walking and above the actual dialogue bar while speaking, including large-text reflow. The Captions setting, modal/cinematic suppression and authored three-second lifetime remain active.

The three UI effects have empty captions in presentation_media.json. The manifest builder also suppresses UI captions so regeneration preserves the change. Essential machine, door, warning and radio cues keep their existing text.

Integration beyond the task's two listed paths is limited to the HUD's two-line accessibility/layout binding, the media builder's UI-caption filter, the integrated test/capture script and required production records. The test uses isolated temporary saves and real campaign/HUD/audio services.

Verification command: `GODOT=/Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated game/tools/run_tests.sh`. Full output: M1-61_tests.txt. Last line: **39/39 suites passed**. This includes test_player_text.gd (354 checks), test_performance_runtime.gd (537 checks, no retry needed) and test_sound_captions.gd (82 checks). The caption suite checks real walking/dialogue layouts, large text, the longest authored dialogue with simultaneous cues, resized viewports, settings, playback of UI effects, missing-media fallback and expiry. The media-builder function was also executed in memory and its UI captions checked without rewriting unrelated manifest fields. Shell syntax, Python compilation, diff whitespace and board consistency checks pass.

Windowed capture is deferred under the user's sandbox exception: the required godot_gated wrapper refused the attempted capture with exit 3 before starting Godot (see M1-61_capture_sandbox.txt), because CODEX_SANDBOX is set. Run M1-61_capture.sh outside the sandbox from a logged-in desktop. It launches through godot_gated/heavy.py, rejects script errors and missing PASS markers, validates PNG signatures/dimensions, and requires all recorded probes to pass.

The night-shift runner then ran M1-61_capture.sh outside the sandbox (1280×720, Forward+, Metal): `SOUND CAPTIONS RESULT: PASS (86 checks, 0 failures)` and `M1-61 evidence verified: 4 screenshots, 86 passing probes` (M1-61_capture_output.txt; every value in M1-61_probes.json is true). Files:

- M1-61_walking.png: walking state, `[ventilation fans]` on the dark-glass panel at the bottom-left safe edge, aligned with the objective card; no dialogue bar.
- M1-61_dialogue.png: Kai's line in the dialogue bar; the sound panel sits 8 px above the bar's top edge, outside the centre third.
- M1-61_walking_large_text.png and M1-61_dialogue_large_text.png: the same two states at 150% text; the panel grows with the type and still clears the reflowed bar.
- M1-61_probes.json, M1-61_capture.txt (engine log M1-61_capture_engine.log is git-ignored).

## Fix round, 6 November 2026 · Sadman/night-claude2 · Claude Opus 5.5 (night shift)

The automated review returned no findings (the reviewer hit its usage limit), so this round reviewed the change directly. I read the four screenshots and checked them against the task: dark-glass panel, bottom edge, above the dialogue bar when it shows, never in the centre third, no interface captions, Captions setting and three-second timing kept. All of these hold. No code changed in this round. A fresh gated run of `game/tools/run_tests.sh` printed **39/39 suites passed** (test_sound_captions.gd 82, test_player_text.gd 354, test_performance_runtime.gd 537 checks; no retry), and its output now replaces M1-61_tests.txt.

Notes for Sadman (no action needed for this task to stand):

- Ownership: the two-line binding in `game/scripts/ui/chapter1_campaign_hud.gd` (`apply_accessibility` → `runtime.audio.set_caption_layout`) is in Ramim's HUD folder (MASTER_PLAN §7). It is the smallest correct join, because the HUD exposes no public dialogue-bar accessor. Let Ramim know when this lands, or hand that call to Ramim.
- The capture log shows `The object does not have any 'meta' values with the key 'lla_fade'`. It comes from the HUD's existing `_fade` (`get_meta("lla_fade", null)` on first use, also at HEAD), not from this change. It is harmless but noisy, and the fix belongs in Ramim's file.
