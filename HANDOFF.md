# Handoff: Last Light Academy production (27 Oct 2026, night)

## READ THIS FIRST: v7 anime characters (27 Oct, 04:00)

**v8 update (27 Oct, afternoon):** all five characters are now built from the v8 turnaround sheets (arms in one A-pose in every view; side views with the near arm removed), which ended the extra arm Tripo modelled on the v7 backs. Mei's first v8 model carried her left arm twice (forward- and back-swung; the copy was weighted to the spine and stayed behind); Tripo's quad mode repeated it, so her model is the dense generation decimated to 57k in Blender (tools/blender_cleanup.py --rigged). Check any new model from the side and in slices before rigging: a front or back view hides a mirrored arm. Mei's brows stay painted (no_brows): they run into her fringe line. Godot: the player now applies toon materials, FaceAtlas and HairSprings itself; FaceAtlas fits the smooth face lighting to each drawn face (no shading band on the chin); faces ignore sun shadows; the gaze lets go of targets behind the shoulder. The locomotion test (scenes/dev/locomotion_test.tscn) switches characters with 1-5 / Tab. Player test 104 checks pass; gate 49/49.

**Animation fixes (27 Oct, evening), after the user's review of the demo (shrugged shoulders, a hip-forward standing pose, flapping run arms):** tools/retarget_clips.py no longer copies clavicles from the mocap (the library idles shrug 16-29 degrees, the walks drop 12-19): they follow the upper arm like a shoulder blade (rest while hanging, rise only past 60 degrees of lift). Standing idles hang the arms clear of each character's own hips (measured on the mesh), elbows soft and back, palms to the thighs. Standing clips (POSTURE) are tilted to a 2-degree forward spine lean (the idles swayed back 7-18 degrees) and keep 45 % of their knee bend (they crouched 13-26 degrees). Walks and runs keep the wrists nearly straight and get one cyclic smoothing pass on the arms; the player samples gait cycles through cubic rotation curves. Checks: shoulder tops at or below rest in idle, spine lean +0..+2, idle knees 5-12 degrees, no arm pops in stops, turns and pivots (per-frame arm rotation logged in Godot). Second pass (same evening, after the user's next test): Amara, Mei and Rafi walk with Kai's Quick_Walk (their library walks were a posed-hands 'thoughtful' walk, a glitchy cycle and a hip-swaying swagger; tools/build_character_v7.sh); a rest hand roll beyond 40 degrees off palm-down is corrected in every clip (Amara's sculpt holds her hands ~90 degrees round, which turned her palms backward); the player no longer plays the library SprintStop and RunToWalk one-shots (the arms flailed up to 57 degrees a frame): stops and slow-downs blend down through the gaits. Codex review fixes: the hang palm table no longer overwrites the finger-pose PALM (thumbs), the palm twist turns about the forearm itself, the arm smoothing keeps duplicated loop ends equal (tools/test_smooth_cycle.py), and the cubic sampling works on a copy. Palms now face the body at 12-46 degrees on average in walk, run and sprint for all five.

**Late 27 Oct (walks, showcase, cutscenes v7):** everyone now walks with their own rig's plain walk, like Ferreira (the user's reference). The team showcase is `game/scenes/dev/asset_showcase.tscn` (C plays cutscenes). CS-01 to CS-03 were remade in the anime style (41-47 s each), with masters and sources in `production/cutscenes/v7/`. ElevenLabs credits are exhausted, so CS-04 to CS-18 wait on the user. Details: handbook section 10 (first entry) and section 6 step 5. Props and holds pass (27 Oct, 20:40): handbook section 10, first entry.

**27 Oct Codex update:** hold layer and review are complete. See [codex_readiness_report.md](production/review/codex_readiness_report.md) for all section 8 assets, Chapter 1 priorities, fixes and exact tests. Seven Godot suites pass; 49 GLBs and three portraits load; both hold clips work on all five v7 rigs. No assets were edited/generated/rendered by this pass. Patch helpers pass array tests; Blender crashed before the additional read-only integration probe. Next: restore Blender validation, visually check toon/face/holds, then assemble the Chapter 1 rooms, UI and interactions. Missing audio/cutscene integration and old-style props remain open.

The art style changed on 27 Oct: realistic was tried and dropped the same day; the user then asked for toon/anime and let Claude pick. **Style A, anime cel-shaded** (production/concept/style_v7/A2.png) is the direction: drawn eye/mouth face layers instead of a bending face mesh, natural proportions for motion capture, cel shading. ART_BIBLE section 1 and the handbook's locked decisions record it. Ferreira is now the v6/v7 design (dark brown pixie cut streaked with grey); older notes about her jet-black hair are superseded.

**Done tonight (all five: Kai, Amara, Mei, Rafi, Ferreira), installed in Godot, gate 49/49 passing:**
- Views: `production/concept/turnarounds_v7/<name>/views/{front,left,back,right}.jpg` (Nano Banana Pro, Topaz 4x, mirrored so the flag is on the LEFT sleeve).
- Models: Tripo multiview v3.1, detailed, quad, 30k-face limit (~57k triangles, 4K textures). `tools/prep_tripo_character.py` orients (-Y), scales to height (Kai 1.74, Amara 1.72, Mei 1.60, Rafi 1.84, Ferreira 1.68) and grounds them.
- Rigs: Tripo API Mixamo rig (65 bones, fingers) as the final skeleton; Meshy rig (REST, `tools/meshy_rig_local.py`) as the motion source. Meshy MCP in the chat still points at an old 1-credit key; the REST helpers read the new key from `~/.claude.json` (979 credits at the start of the night). `tools/meshy_post.py` posts any Meshy job.
- Clips: 42 per character (`tools/build_character_v7.sh`, which runs `retarget_clips.py`): idles, talk/listen, sit, actions, story motions (Pollinate, Water, Inspect, Type, Repair, Carry_loop), the character's own walk/run (`Walk_loop`, `Run_loop`), neutral `WalkBasic_loop`/`RunBasic_loop`, `Sprint_loop`, `RunToWalk`, `SprintStop`, turns `TurnIdleL/R`, `TurnWalkL/R`, `TurnRunL/R`, six Hand* poses. Names in `tools/clip_names.py`.
- Face: `tools/render_face_flat.py` -> `tools/make_toon_face_atlas.py` (landmarks `production/rigs/face_landmarks_v7.json`) -> `tools/add_toon_face.py`. Layers FaceEyeL/R, FaceBrowL/R, FaceMouth (Kai has no brow layers), skinned to Head, 0.7 mm off the skin, cell 0 transparent (the painted feature shows). Atlas layouts: eyes 3x2 (open, half, closed, happy, wide, worried), brows 2x2 (neutral, raised, lowered, worried), mouth 3x3 Rhubarb (X, A..H). The skin fill must be lit exactly like the skin (same toon ramp, weak normal map on the face) or the layer edges show.
- Mei: three ponytail bones (`tools/add_ponytail_bones.py`, swing-tested, worst stretch 3.3x at the root under an exaggerated swing).
- Builds: `production/models/v7/CH_<Name>/CH_<Name>.glb` = `production/models/final/...` = `game/assets/characters/...` (old v4 finals in `production/models/archive/characters_v4/`).

**Day update (27 Oct, midday), all installed, gate 49/49, all seven Godot test suites pass:**
- Patches: the AI-painted flag placeholders (sleeve, and stray copies Tripo painted on the upper back) are now painted out of the colour, normal and roughness textures by `tools/add_patches.py` (`paint_out_flags`); no cover layers. Flag green is told apart by hue, value and saturation, so Amara's teal tabs and name tape are kept. The reviewed cleanup now leaves ambiguous green-only details untouched and checks only its approved colour/geometry mask; do not infer a semantic safety guarantee from a global green count. The crisp `PatchFlagL` / `PatchAuroraR` layers sit on clean fabric. Known minor: a faint smooth rectangle where the normal map was filled on Rafi's and Ferreira's upper backs, visible only in close PBR renders.
- Hold poses: `tools/add_hold_poses.py` adds `CarryBox_pose` (small case at the belly, both hands) and `HoldRight_pose` (mug-sized item, right hand) to all five, so 44 clips. They are upper-body poses for the game to layer on the arm bones; `Carry_loop` stays for big crates held by their sides. `finish_character_v7.sh` runs it last and now stops on any failed Blender step.
- Toon look fixed in Godot (it rendered the cast black): the shaders multiplied by albedo inside `light()` (Godot does that afterwards) and copied glTF's default metallic factor 1.0 (diffuse zero). Shared ramp: `game/shaders/toon_ramp.gdshaderinc` (key light paints two bands and tints the shadow side; fill and rim lights only add). Outlines are thinner and grow sideways on screen only. FaceAtlas picked the bottom-up atlas row and lost its atlas when set up twice; both fixed, and the v7 left-eye atlas is no longer mirrored.
- Look-dev: `game/scenes/look/anime_lookdev.tscn`, render with `Godot --path game --write-movie <out.png> --fixed-fps 10 --quit-after 40 res://scenes/look/anime_lookdev.tscn -- --closeup=<cast index>[:<metres>]`.
- Motion review: strips of all 42 clips for all five checked (session scratchpad `v7_3d/strips/`); Inspect re-rendered after the trim. No broken poses or hands found.

**Codex:** the hold/review/readiness pass above is complete; the previous queue status is superseded. `PlayerController.set_hold(PlayerAnimation.Hold.BOX/RIGHT/NONE)` layers the installed poses; H cycles them in the locomotion test scene. The report records current deliverables and remaining work.

**Next, in order:**
1. Read Codex's summary and readiness report; re-run all tests in `game/tools/`.
2. Act on the readiness audit: toon treatment for props, plants and environments, then rebuild only what it flags (Chapter 1 slice first).
3. Cutscenes: the 23 masters are in the old style; re-render from the new characters once the look is signed off.
4. Later: Ferreira's Earth duty-layer variant, EVA suits for later chapters, a real mug/case attach point per prop.


For the next Claude Code session (another account) taking over asset and cutscene production. Read in this order: `CLAUDE.md`, `PRODUCTION_HANDBOOK.md` (source of truth: canon, locked decisions, pipeline, tools, status), then this file. Project memory (on this Mac) is in `~/.claude/projects/-Users-sadmansakib-nasa-space-apps-2026/memory/`.

## Goal and standing instructions

- Make every asset and cutscene **perfect, Steam-release quality** before the 13–14 Nov 2026 Dhaka hackathon.
- **Credits:** ElevenLabs and Meshy are effectively unlimited (the user has more accounts), so don't ration them; state the cost in one line before big batches. Tripo is limited (about 2,375 CLI credits).
- **Delegation:** use Codex (`gpt-6-astra`, high effort) heavily for reviews, audits and small scripts. Codex hit its weekly limit on 26 Oct; it resets about 27 Oct. Antigravity is for UI and browser work only.
- **Rules:** verify every asset when it's made, keep folders and git clean, and tell the user immediately if a tool is missing. Commit only when asked, as `sadmanqt`, with no AI co-author lines.
- **Never print API keys.** The user pasted their Meshy key in chat on 26 Oct, so remind them to rotate it.
- **Locked:**
  - Godot 4.7, Forward+, anime cel-shaded (style A) since 27 Oct.
  - Bangladesh flag on every crew member's LEFT sleeve; round mustard-flower and crescent Aurora patch on the right chest and right shoulder; no NASA marks.
  - No Bangla script; plants never have faces.
  - Ferreira: v7 design, dark brown pixie cut streaked with grey (supersedes the older jet-black note).
  - Moon rules: black sky, no stars over sunlit ground, no billowing dust, no light beams in vacuum.

## Status right now

**Cutscenes: 23 of 23 done and reviewed.** See `production/cutscenes/shots.csv` (status and ElevenLabs IDs) and `production/review/cutscene_review.md` (every verdict, rejected Codex claims, polish backlog). Masters are in `production/cutscenes/masters/`.
- A Codex audit on 26 Oct found star chest badges, grey Ferreira hair and lettered patches. These were fixed and re-rendered: CS-05-A, CS-07-A, CS-09-A, CS-10-A, CS-12-A, CS-13-A.
- CS-02-A was graded in post. CS-17-A had its stars removed in post.
- **To do:** have Codex re-review those six re-renders once its limit resets (Claude-only review so far).

**3D assets:** 49 in Godot, 44 props and environment pieces plus 5 characters; all passed the gate before the character swap below.
- PR_Dosimeter was fixed on 26 Oct: its baked screen is gone, and it now has its own flat `Screen` material slot for a live UI.

**Characters: in progress (Meshy upgrade).** The Tripo 78-bone rigs had no animation clips, so all five were re-rigged with Meshy (24-bone humanoid, no finger bones) and given 19 clips each:
- **Looping (9):** Walk, Run, Idle (Idle_3), IdleAlt (Idle_9), Breathe, Listen, Talk, SitIdle, LookAround.
- **One-shot (10):** Agree, OpenDoor, PickUp, KneelStand, Wave, Cheer, Drink, Push, SitDown, StandUp.
- Assembled GLBs are now in `production/models/final/CH_*/CH_*.glb`. Raw Meshy files and the old Tripo rigs (`tripo_rig78.glb`) are in `production/models/meshy/CH_*/` (git-ignored).
- `manifest/characters.csv` now says `bones=24`, `clips=19/9`. The gate (`verify_gate.py` + `game/tools/verify_assets.gd`) now also checks clip and loop counts.
- A sync + gate + registry run was started at handoff; its output is in `production/review/last_sync.log`.

**Done since the handoff (26 Oct, second account):**
- The characters had imported at 1/100 scale. Meshy rigs sit under a 0.01-scaled `Armature` node with bones in centimetres. `production/tools/glb_unscale_armature.py` bakes that into metres, and `assemble_character.py` now runs it automatically.
- All 49 assets pass the gate (heights correct, 24 bones, 19 clips, 9 looping; the `_loop` names import as loops). The registry shows 49 verified.
- All 95 clips checked visually with `render_anim.py --action all` (each clip framed on its own motion); all pass. Noted in `visual_review.md`.
- Six story motions added to every character (Pollinate, Water, Inspect, Type, Repair from Meshy text-to-motion; Carry_loop from library preset 611). Characters now have 25 clips, 10 looping; the gate passes; every clip checked visually. This closes AN_CadetLocomotion, AN_CadetCare and AN_RepairVehicle.
- Codex re-reviewed the six audit re-renders: all PASS.
- `pose_test.py` works with Meshy and Tripo names. The handbook (tools table, character step 5, status) and the prompt log are updated.

**Next:**
- Lip-sync for CS-01-B.
- Real UI art on in-world screens.
- Godot collision and lightmap UVs for props (post-import script).
- The 29 planned assets (the environment kit; 2D sheets need the user's approval for hero props and characters).
- Audio.
- `.ogv` conversion (needs an ffmpeg built with libtheora).

## v5 (27 Oct, night): after the user's second review. READ THIS FIRST

The user said hands, wrists and shoulders looked inhuman, motion unnatural, renders cheap; target look: clean stylised game (Fortnite/Overwatch direction). A side-by-side with Meshy's own rig showed the arm/shoulder motion matched; the problem was one resting finger curl baked into every clip (read as a claw on the short glove fingers) plus flat grey lighting.
- `retarget_clips.py` HANDS table: hand pose per clip (soft default, open for Wave/Cheer/Push, grip for Repair/Drink/Water/OpenDoor, pinch for Pollinate/PickUp). All five rebuilt (`scratchpad/v4/<CH>/<CH>.glb` are the current builds).
- `production/tools/blender_look.py`: shared game lighting (studio HDRI hidden from camera, warm key, cool fill and rim, AgX medium-high contrast) used by `render_showcase.py` (new: clip showcase videos), `render_context.py` and `render_lipsync.py`.
- Demo v5 published (same link). Renders in `scratchpad/v5/`.
- Verified Codex work: `test_lip_sync.gd` 15 PASS, `test_face_expression.gd` 65 PASS (incl. Kai GLTF integration, head accent), `test_review_scene.gd` 447 PASS on all five; Walk_loop is in place and the planted foot moves 1.44-1.47 m/s (game must move Kai at ~1.45 m/s); `mesh_audit.py --selftest` PASS.
- Running on Codex account 1 (default CODEX_HOME): Godot look-dev scene (`scratchpad/codex_look/prompt.txt`, out.txt) and the mesh audit of the five builds + props (`codex_audit/prompt3.txt`, out3.txt). Codex account 2 (`~/.codex-2`) is limited until 27 Oct 03:43.

## Character rebuild v4 (26 Oct, evening): external audit fixes. READ THIS FIRST

The user pasted an external audit of the Kai v3 demo (mouth, hands, shoulders, stance, actions, presentation). Every finding, its owner, fix and status is in `production/review/character_defect_ledger.md`; keep it updated. All five characters are rebuilt with the fixes in the session scratchpad
`/private/tmp/claude-501/-Users-sadmansakib-nasa-space-apps-2026/8b783e13-4d3f-4549-8fec-ee82b9a2d7f4/scratchpad/v4/<CH_Name>/<CH_Name>.glb` (65 bones, 24 clips + 6 hand poses, 21 shape keys). Nothing is installed in `game/` or `production/models/final` yet.

One command builds a character from its Tripo Mixamo rig and Meshy clips (face rig, retarget, hands, review sheets):
`production/tools/build_character_v3.sh <CH_Name> <height> <tripo_rig.glb> <meshy_dir> <out_dir>` (set FORCE_FACE=1 to redo the face rig). Inputs per character: Kai `scratchpad/apose/tripo_rig/model_url.glb` + `scratchpad/apose_md`; the others `scratchpad/rebuild/<amara|mei|rafi2|ferreira>/tripo_rig/model_url.glb` + `scratchpad/rebuild/<same>`; heights Kai 1.74, Amara 1.68, Mei 1.62, Rafi 1.78, Ferreira 1.70. `scratchpad/rebuild/build_all.sh` runs all five (two at a time).

New and changed tools (all in `production/tools/`):
- `add_mouth_rig.py`: face rig v2: lip cut with inner lip surfaces, cavity tube, crowns and gums, tongue, eyelids (blink), brows; 21 keys; needs `--landmarks rigs/face_landmarks.json --name CH_X` (eye/brow positions marked by hand on the standard flat face view; the lip search starts below the eyes).
- `retarget_clips.py`: hand solver rewritten (true hinge axes, thumb solver fixed, 6 poses incl. Open and Pinch, left from the mirrored right); SETTLE relaxes arms in standing clips.
- `retarget_clips.py` floor contact: feet zeroed on the standing idle (Meshy clips stand ~25 degrees off the bind pose), then per frame the lowest boot or knee point sits on the floor whenever a source foot is down. Known: PickUp's fingers reach ~7 cm under the floor (needs IK or another clip); sit clips want a seat ~5 cm higher than PR_CrewSeat; typing hands are 15 cm above PR_ControlConsole's desk.
- Review renderers: `render_face.py` (shape keys x 4 angles), `render_hands.py` (both hands x 4 views), `render_stress.py` (shoulder range), `render_context.py` (clips with real props on a floor, measured contacts), `render_lipsync.py` (speech video with waveform/cue/weight overlay and closure timing; same coarticulation as the game).
- `rhubarb_visemes.py` now writes a loudness envelope `env`.
- Godot: `game/scripts/lip_sync.gd` (coarticulation, closures, loudness, audio clock, pause/seek, crossfade), test `game/tools/test_lip_sync.gd` passes (run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/test_lip_sync.gd`). `face_expression.gd` and the new `head_accent.gd` pass 65 headless checks, including the real scratchpad Kai GLB loaded at runtime; head accent is off by default. Wiring and exact results: `production/review/codex_face_report.md`. The review scene `game/scenes/review/character_review.tscn` (+ `game/scripts/review/`) still parses but is untested.

Demo v4 (published, waiting for the user's sign-off): lip-sync videos `scratchpad/v4/demo/*.mp4`, action scenes on the final build `scratchpad/v4/demo/context4/`, review sheets `scratchpad/v4/review/` and `v4/<CH>/review_*.jpg`. The demo page is `scratchpad/demo/site/kai_rebuild_demo.html`, published at https://claude.ai/artifact/5ryBV3wbq6XPQh8HJsHxp8 (republish the same file to keep the link).

Next, in order:
1. Done 26 Oct 22:30: final builds of all five in `scratchpad/v4/<CH>/<CH>.glb` (face rig with eyelid-tone fix, short-thumb targets, floor contact). Demo v4 published. Waiting for the user's sign-off.
2. After sign-off: install the five builds (`models/final`, `game/assets/characters/CH_*/`), update `manifest/characters.csv` (bones 65, clips 30/10, morphs 21), run the gate, update the handbook.
3. Codex jobs (the Codex workspace ran out of credits; the user is adding a second account at `CODEX_HOME=~/.codex-2`): (a) `test_review_scene.gd` + make the review scene work with the v4 GLBs, hand prop attachments, foot-slide readout (audit B03, Q04, H06); (b) DONE: `face_expression.gd`, `head_accent.gd`, and `test_face_expression.gd` (65 checks including Kai runtime integration; see `production/review/codex_face_report.md`); (c) fix `mesh_audit.py`'s self-test and run it on the five builds and the 44 props (Q05). Briefs are in `scratchpad/codex_face|codex_review|codex_audit/prompt.txt` (run: `CODEX_HOME=~/.codex-2 codex exec -s workspace-write -m gpt-6-astra -c model_reasoning_effort="xhigh" -C <repo> < prompt.txt`).
4. Character voices (ElevenLabs voice design), then voice and time every line.

## Character rebuild v3 (26 Oct, in progress): the new standard for all five cast

The user rejected the first rigs: claw hands, crushed shoulders, a stray glove piece behind every back, no lip-sync. Kai v3 fixes all of it and is waiting for the user's sign-off on the demo page (https://claude.ai/artifact/5ryBV3wbq6XPQh8HJsHxp8). Files are in the scratchpad until approved: `pilot/` and `apose/` under the session scratchpad; the final is `apose/CH_Kai_v3.glb`. Nothing in `production/models/final` has been replaced yet.

Pipeline per character (all tools in `production/tools/`):
1. **Model:** Meshy `meshy_multi_image_to_3d` from the approved turnaround views (`concept/turnarounds/<name>/views/front,right,back,left.png`), with `ai_model meshy-7.1`, `pose_mode a-pose` (not T-pose: that crushed the shoulders), `geometry_resolution 2k`, `texture_resolution 8k`, `enable_pbr`, `should_remesh` + `topology quad` + `target_polycount 40000`. About 40 Meshy credits.
2. **Two rigs on that same A-pose mesh:**
   - The motion source: `meshy_rig` (`input_task_id` = the model task), 5 credits. Then the clips via `meshy_animate`, set 1 `243,249,336,47,313,32|33,337,25,285,274|276` and set 2 `365,290,303,342,259,58,52|53` (F|M variants), plus the 5 story motions by `motion_task_id`. The text-to-motion tasks expire after 3 days; regenerate them if needed (prompts are in AI_PROMPT_LOG.md).
   - The final skeleton: `python3 tools/tripo_api.py rig <meshy.glb> <dir>` (the API pool needs `TRIPO_OPENAPI_KEY` from `~/.zshrc`; the Mixamo spec gives 65 bones with fingers).
3. **Mouth:** `blender -b -P tools/add_mouth_rig.py -- <tripo_rig.glb> <mouth.glb>`.
   - Finds the lip line in a flat front render, cuts it, and adds a mouth interior and teeth.
   - Adds 16 viseme shape keys (OVR names, default 0).
   - Check with a closed-mouth diff (only the lip line may change) and an open "aa" close-up of both corners.
4. **Clips and hands:** `blender -b -P tools/retarget_clips.py -- <mouth.glb> <height> <out.glb> walking.glb running.glb clips1.glb clips2.glb Pollinate=... Water=... Inspect=... Type=... Repair=...`.
   - Transfers each clip as world-space rotation deltas.
   - Solves the relaxed hand into every clip.
   - Adds the HandRelaxed, HandGrip, HandFist and HandPoint poses.
5. **Check:** `render_anim.py --action all` sheets, shoulder close-ups (arms should move only about 15° from rest), and hand poses. Then install to `models/final`, sync, gate, registry. Update `manifest/characters.csv`: bones 65, clips 28/10 (24 clips plus 4 hand poses), and tris about 75k.
6. **Lip-sync per voice line:** `python3 tools/rhubarb_visemes.py <line.wav|mp3> <cues.json> --text "<line>"` (Rhubarb 1.14 at `~/.local/bin/rhubarb`). In Godot, `game/scripts/lip_sync.gd` (LipSync node, `play_line(stream, cues_path)`) drives the blend shapes from the audio clock. Its test: `Godot --headless --path game --script res://tools/test_lip_sync.gd`.

Open items:
- The fist thumb doesn't wrap over the fingers. The solver target is in `hand_pose()` in `retarget_clips.py`; its error is about 4–5 cm.
- Carry was dropped.
- Then rebuild Amara (1.68 m), Mei (1.62), Rafi (1.78) and Ferreira (1.70) the same way. Step 1 started 26 Oct: Meshy A-pose model tasks Amara `01a177eb-3f78-77bf-84f9-b2212c4bc8cb`, Mei `01a177eb-4ad1-7182-aa31-71d5a0f3e024`, Rafi `01a177eb-53c8-7642-b5c5-06b372edb42f`, Ferreira `01a177eb-5e27-70c2-b24d-246a66c98745` (same settings as Kai; download with `tools/meshy_fetch.py`).

  Progress (scratchpad `rebuild/<name>/`):
  - All four models checked against the concept sheets, front and face close-ups. Rafi's first model was rejected (lumpy cheek, lopsided smile, skin showing through the hair). It was regenerated as `01a177f3-9a71-7597-b2f6-09b8a1a35d9a` (in `rebuild/rafi2/`), which is clean.
  - Amara, Mei and Ferreira (all female clip variants) have Meshy rigs and their Tripo Mixamo rigs (`tripo_rig/model_url.glb`). The mouth rig is running, and all 21 clip tasks are submitted (listed in `<name>/tasks.txt`, downloading to `<name>/clips/`):
    - Amara: rig `01a177f3-c487-734f-b1d4-0ad2499216da`; clips1 `01a177f7-0411-72a1-8d23-c807607d81ae`, clips2 `01a177f7-0a32-76aa-b1dd-6b5c073de479`, Pollinate `01a177f7-10b1-7544-86a1-a2fff9f85435`, Water `01a177f7-17e7-7537-9e74-4ae5e5d31f63`, Inspect `01a177f7-1f1d-7505-b0b4-473a6713eba1`, Type `01a177f7-2595-728e-ab32-21861d0d128f`, Repair `01a177f7-2c4d-738d-aa0a-fd0bd16a7798`
    - Mei: rig `01a177f3-e5d4-7079-b010-670f42776618`; clips1 `01a177f8-5a8a-76fa-883b-a71e8f7db80a`, clips2 `01a177f8-e7a3-7358-8383-63b90965b70e`, Pollinate `01a177f8-edcf-72f9-8b71-86cda917ac40`, Water `01a177f8-6707-74e4-827a-3bf1572bef51`, Inspect `01a177f8-6e52-74c4-b5f9-68290294ab0b`, Type `01a177f8-f4bd-7056-8de3-3354497da467`, Repair `01a177f8-786f-7022-9fe2-29088f391427`
    - Ferreira: rig `01a177f4-0340-7451-967c-27de1fbbda60`; clips1 `01a177f8-08e8-7309-88e9-ff05f4184bc7`, clips2 `01a177f8-0fbd-7495-87f3-dba19980ef13`, Pollinate `01a177f8-1569-7636-8cc5-e215ea219007`, Water `01a177f8-211c-7775-946d-f6d3777ffcd8`, Inspect `01a177f8-2a34-7400-ad5c-fb4bd9e41db2`, Type `01a177f8-3272-74b5-a936-c7ca6fada4a1`, Repair `01a177f8-39ef-7471-826e-a1e16288361d`
  - Rafi v2 (male variants) has its Tripo rig running. Its Meshy rig, clips and story motions need a fresh Meshy account (this one is at about 1 credit). On the new account, post the model GLB with `tools/meshy_rig_local.py` (height 1.78); the old account's task IDs, including the story-motion IDs, are not visible to a new account, so regenerate the 5 story motions from the prompts in AI_PROMPT_LOG.md.
- Meshy has only 414 credits left (enough for about 3 characters): the user will switch accounts when asked.
- Characters' own ElevenLabs voices are still to be designed; the current test voice is the stand-in "Ali".

## Meshy task IDs (all succeeded, 26 Oct)

| Character | Rig task | Clips set 1 (10) | Clips set 2 (8) |
|---|---|---|---|
| Kai | 01a176ad-8f00-7620-b44b-d7863e47e415 | 01a176b1-c896-7244-9abb-774b37f6df35 | 01a176b7-460e-7553-a695-753c70ac952d |
| Amara | 01a176b0-9a1c-70de-8853-001a28610b5f | 01a176b3-4ff7-773e-92b1-a062c2fa28d8 | 01a176b7-47fd-7213-9924-3b27142f991f |
| Mei | 01a176b0-d8dd-7728-a641-351a6cef5d59 | 01a176b3-525f-7075-b6eb-e3f142cb216b | 01a176b7-49e3-7133-b9a1-345504a01677 |
| Rafi | 01a176b1-1532-765a-b3e8-279c56aba0b2 | 01a176b3-5476-75b9-ad39-5e91345f0d38 | 01a176b7-4c24-7141-b454-d0899ba907d9 |
| Ferreira | 01a176b1-5491-77d0-8e86-5129b74030d3 | 01a176b3-56a2-73be-ad93-077e345d5d0c | 01a176b7-4e37-7301-8bfe-e7dcfed4f4c6 |

- **Set 1 action ids:** 0, 47, 313, 25, 285, 274 or 276 (pick-up, female or male), 365, 32 or 33 (chair sit, female or male), 337, 290. Library id 0, "Idle", is dropped as a fighter's stance.
- **Set 2 action ids:** 243, 249, 58, 52 or 53 (sit-to-stand, female or male), 336, 303, 342, 259. All at 30 fps.
- Meshy balance after this: about 805 of 1,100 monthly credits; it resets 25 Nov.

## How-tos learned the hard way

- **Meshy rig needs a model URL.** Post local GLBs as a data URI through the REST API:
  ```
  blender -b -P production/tools/strip_rig.py -- in.glb static.glb
  python3 production/tools/meshy_rig_local.py static.glb <height_m>
  python3 production/tools/meshy_fetch.py rigging|animations <task_id> <dir> [names]
  ```
  Then build the game file with `production/tools/assemble_character.py`. Its clip files contain only base-colour textures, so the mesh always comes from the rigged model. The key is read from `~/.claude.json` and never printed.
- **ElevenLabs connector (2), flow `CausC2kFXXiuy3wFDEwH`:**
  - Use Seedance model `bytedance-seedance-v2.5`; the `-us` variants are region-blocked.
  - Before editing a take, pin it with `creative_add_flow_asset_node`. Gemini (`gemini-3-pro-image`) keeps faces best but confuses left and right. GPT Image 2.5 Sunburst places sleeve details correctly when the sleeve is named by its neighbour.
  - Watch for a take swapping the flags for Pakistan flags.
  - Describe what you want rather than what to avoid ("no dust" produced dust).
- **Post-processing tools:**
  - `production/tools/clear_stars.py`: stars, plus `--grade-sky`.
  - `production/tools/blank_texture_region.py`: paint out baked text or screens, with `--screen`.
  - `production/tools/intake_shot.sh <shot> '<url>'`: saves a master and its review strip.
  - `production/tools/render_anim.py`: animation contact sheets.
- **Codex:** `-i` is variadic, so pass the prompt on stdin:
  ```
  codex exec -s read-only -m gpt-6-astra -c model_reasoning_effort="high" -i a.png -i b.png < prompt.txt
  ```
  Run it in the background and write output to a file.
- **Safety hook:** `rm -f` and `rm -rf $VAR` are blocked; don't retry them.
- **OCR:** none is installed. macOS Vision via a short Swift script works; it was used for the text sweep of the cutscenes.
