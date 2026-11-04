# Last Light Academy — Production Handbook

**Read this first.** This is the single source of truth for making the game's assets and cutscenes: what is canon, what has been decided, how the pipeline works, what exists, and what is next. It is written for every team member and for AI agents (Claude Code, Codex, Antigravity). If you change a decision, change it here in the same commit.

Last updated: 4 November 2026.

---

## 0. Where to find things

| I need… | Look here |
|---|---|
| Any asset (made or planned), its file, source and status | [production/ASSET_REGISTRY.csv](production/ASSET_REGISTRY.csv) |
| The game-ready files Godot loads | [game/assets/](game/assets/) (layout in its README) |
| Whether an asset passed its checks | [production/review/asset_verification.md](production/review/asset_verification.md) and [visual_review.md](production/review/visual_review.md) |
| Every dialogue line, speaker and voice file name | [production/audio/vo_lines.csv](production/audio/vo_lines.csv) |
| Music cues and where they play | [production/audio/music_cues.csv](production/audio/music_cues.csv) |
| Sound effects and their captions | [production/audio/sfx_list.csv](production/audio/sfx_list.csv) |
| Cutscene shots with ready Seedance prompts | [production/cutscenes/shots.csv](production/cutscenes/shots.csv) |
| All 96 final scenes with locations | [production/manifest/scene_index.csv](production/manifest/scene_index.csv) |
| The look and the science rules | [production/ART_BIBLE.md](production/ART_BIBLE.md) |
| What every AI generation was | [production/AI_PROMPT_LOG.md](production/AI_PROMPT_LOG.md) |
| How to make or check an asset | Section 6, scripts in [production/tools/](production/tools/) |
| Detailed AI execution prompts for the complete game | [execution/00_START_HERE.md](execution/00_START_HERE.md), [master executor](execution/01_MASTER_EXECUTOR.md), and [coverage index](execution/99_COVERAGE_MATRIX.md) |
| **What to work on next ("go next")** | The team board: [production/plan/BOARD.html](production/plan/BOARD.html) (view), [tasks.json](production/plan/tasks.json) (source), protocol in [GO_NEXT.md](production/plan/GO_NEXT.md) |
| Whether the project meets the competition rules | [docs/competition-rules.md](docs/competition-rules.md) section H |

## 1. Project in one paragraph

*Last Light Academy* is a 3D educational game for NASA Space Apps Challenge 2026 (challenge: "Build a Junior Astronaut Mission Trainer"; team The Last BrainCell, Bangladesh). Four cadets run Aurora Station on the Moon's south pole (April 2046 to April 2047), keep a mustard plant named Alo alive through a 36-hour lunar night, grow the first Moon garden and uncover who left the seeds (Dr Noor Rahman of Expedition Zero). Eight chapters, 32 missions, 96 scenes, about 12 hours. The Dhaka hackathon is **13–14 November 2026**.

## 2. Canon: which document wins

| Topic | Authority (latest pulled, final) | Notes |
|---|---|---|
| **Story, scenes, dialogue, chronology** | [full-game-story/STORY_FULL.md](full-game-story/STORY_FULL.md) and its data [full-game-story/story-data.json](full-game-story/story-data.json) | 10–14 h edition (commit `30e9728`). Supersedes the older 4-hour scope and the SC-xxxx scene list. Scene IDs are `EX-CHxx-Sxx`. |
| **Scene index for production** | [production/manifest/scene_index.csv](production/manifest/scene_index.csv) | Generated from story-data.json: all 96 scenes with mission, legacy SC ID, location and story time. |
| **Game rules and numbers** | [game-design/08_PUZZLE_DESIGNS.md](game-design/08_PUZZLE_DESIGNS.md) (P-01 to P-16), [docs/GAMEPLAY_DESIGN_FINAL.md](docs/GAMEPLAY_DESIGN_FINAL.md), [game-design/10_GAMEPLAY_SYSTEMS.md](game-design/10_GAMEPLAY_SYSTEMS.md) | Numeric contracts (energy 14/20, air 6/10, PUMP/STACK/WAIT, etc.) are unchanged by the story expansion. |
| **Places** | [game-design/09_WORLD_AND_LEVEL_DESIGN.md](game-design/09_WORLD_AND_LEVEL_DESIGN.md) | LOC-01 to LOC-12 sizes and connections. |
| **Characters** | [game-design/04_CHARACTER_BIBLE.md](game-design/04_CHARACTER_BIBLE.md) | Except the overrides in section 3 below. |
| **Cutscene direction** | [game-design/12_CINEMATIC_DIRECTION.md](game-design/12_CINEMATIC_DIRECTION.md) | CIN-01 to CIN-14, remapped to final scenes in section 9. |
| **Look of every asset** | [production/ART_BIBLE.md](production/ART_BIBLE.md) | Palette, lighting, science rules, polygon budgets, naming. |
| **Competition rules** | [docs/competition-rules.md](docs/competition-rules.md) | Dates, videos, AI disclosure, no NASA logos. |

When an older design doc disagrees with the latest story or with section 3, **the latest story and section 3 win.** Known conflicts are listed in section 12.

## 3. Locked decisions (do not change without the user)

| Date | Decision |
|---|---|
| 25 Oct 2026 | The Dhaka Local Lead gave permission to build production assets and cutscenes before the hackathon. Target: full production, deploy-ready, high-end. Keep that permission in writing for the submission. |
| 25 Oct 2026 | Engine: **Godot 4.7, Forward+ renderer**, GLB assets. Keep LODs so a Compatibility (low-spec) build still works. |
| ~~25 Oct 2026~~ | ~~Art style: stylised-realistic.~~ Superseded 27 Oct. |
| 27 Oct 2026 (later) | Art style changes again to **toon or anime** (user: realistic is too heavy). Claude picked and installed **style A, anime cel-shaded** (user delegated the choice: best for clean rigging and facial animation; drawn, swapped eyes and mouths; natural proportions for mocap). Tests are in [production/concept/style_v7/](production/concept/style_v7/); the current v7/v8 turnarounds and installed GLBs are the runtime references. Faces, heights and kit from the approved current designs carry over. Pipeline: Tripo/Meshy from approved turnarounds, Blender clean-up, hand-built skeleton with twist bones, toon face with swapped eye and mouth drawings, mocap clips, Godot movement system. |
| ~~27 Oct 2026~~ | ~~Art style: realistic and warm.~~ Superseded the same day by toon or anime. Kept: the **third-person follow camera like Death Stranding** ([gameplay spec](docs/GAMEPLAY_DESIGN_FINAL.md) section 3), adult cadets with distinct silhouettes, the navy duty coverall as the main costume. |
| 27 Oct 2026 | **No paid tools** (user: no budget): only free tools and credits on plans the user already has. Character Creator 5 dropped; MetaHuman (free) was offered with a setup tutorial (https://claude.ai/artifact/5xtGrwFzyRQRH38DASV5En) but is on hold since the switch to toon or anime. Image-to-3D (Tripo, Meshy) is used again for people, with a hand-built skeleton and toon face in Blender. |
| ~~25 Oct 2026~~ | ~~Suit: the soft stylised suit.~~ Superseded 27 Oct: the main costume is the navy **duty coverall** (cadets work unsuited indoors); the EVA suit becomes a realistic soft-goods suit in the same white/navy/orange scheme, as a second outfit. |
| 25 Oct 2026 | Patches: **Bangladesh flag on the LEFT shoulder**, round **Aurora mission patch** (yellow mustard flower and crescent Moon) on the RIGHT shoulder and right chest. **Never the NASA meatball or worm**, and nothing that implies NASA endorsement. |
| 25 Oct 2026 | **No Bangla script anywhere in the game.** English only. The seed packet reads "ALO" and "N." in Latin letters. |
| 25 Oct 2026 | **Plants never have eyes, faces or mouths.** Alo's personality comes from posture and movement only. |
| ~~25 Oct 2026~~ | ~~Cutscenes: Seedance 2.5 through the ElevenLabs connector.~~ Superseded 3 Nov for new shots. |
| 3 Nov 2026 | Generated cutscene shots use **Google Veo** (Flow or the Gemini app on the user's Google AI Pro accounts; generate freely, the user has several accounts), from start frames rendered from the final 3D models, per the user's standing rule to prefer Veo when Veo and ElevenLabs can both do it. ElevenLabs is for voice, music and sound effects. The three finished v7 cuts (CS-01 to CS-03) stay as they are; their three push-in shots are re-made with Veo. |
| ~~25 Oct 2026~~ | ~~The five stylised cast turnarounds are approved.~~ Superseded 27 Oct by the v6 realistic designs in [production/concept/cast_v6/](production/concept/cast_v6/), which the anime cel style replaced the same day (row above). The current cast is built from the v8 turnaround sheets in [production/concept/turnarounds_v8/](production/concept/turnarounds_v8/); the installed GLBs are the runtime reference. |
| standing | Every AI-generated asset is logged in [production/AI_PROMPT_LOG.md](production/AI_PROMPT_LOG.md) (tool, model, prompt, inputs, result, human changes). The Bangladesh guide requires this. |
| standing | The user approves 2D design sheets before Tripo credits are spent on new characters or hero props. |

## 4. Story facts every asset and cutscene must respect

**Cast and presence**

| Character | Role | Age | Where they are |
|---|---|---|---|
| Kai | Power and heat (orange) | 19 | Aurora all game; rover in CH04 and CH08 |
| Amara | Atmosphere and measurement (cyan) | 20 | Aurora all game (stays home in CH04 and CH08) |
| Mei | Horticulture (green) | 19 | Aurora all game (stays home in CH04 and CH08) |
| Rafi | Safety and field operations (purple) | 20 | Aurora; rover in CH04 and CH08 |
| Commander Ferreira | Commander (gold tabs), Expedition Zero's engineer in 2034 | mid-40s | **Earth screen only until she arrives on 12 Dec 2046** (relief flight 8–12 Dec); physical at Aurora after; rover in CH08 |
| Rao | Earth flight controller | adult | Earth screen only, always |
| Dr Noor Rahman ("N.") | Botanist, Academy founder, Bangladeshi | older adult | Earth only. Stored recordings and text until CH08; **first live voice only in CH08-S10**, after both relay links are verified. Identity revealed only in CH05. |
| Alo | Purple-stem field mustard (Brassica rapa) | plant | Planted 11 Apr 2046, blooms 27 Apr, harvested 21 May, dies naturally. Never revived; later plants are descendants. |
| Tara | Green-stem compatible partner | plant | Indoor reference bay; blooms 30 Apr; equal care and screen time |

**Key ledgers (assets must show these exact counts)**
- Alo harvest: **42 seeds = 12 planted + 30 founder reserve**. The reserve travels as **15 + 15** in the Chapter 7 seed case.
- The 2034 annex holds **young, unflowered seedlings with curled leaves only**: no buds, no flowers, no pods.
- Vault: **12 distinct specimens**. Cotton is planted 15 Dec, leaving **11** stored. The album's 16 cultivar entries are records, not physical seeds.
- CH04 descendant sample: 12 plants, 7 purple stems and 5 green.
- CH08: Ferreira, Kai and Rafi take the rover; Mei and Amara hold Aurora. 120 km each way: 24 h out + 3 h repair + 24 h back = 51 h, provisions 72 h. The base holds 2 people for 33 h, then 5 for 3 h.
- Three road repeaters create four hops: Aurora → R1 → R2 → R3 → summit.

**Science rules (reject any asset or shot that breaks one)**: black sky; no fog, haze, wind or billowing dust on the Moon; hard black shadows and a low Sun; lunar gravity, not zero-g; plants always inside pressurised enclosures; radiation is never visible (instruments only); no airborne sound outside (suit, contact and cabin sound only); impact flashes are not meteor streaks; the eclipse is seen through a filtered camera with a labelled conceptual Earth-limb diagram; the 2017 storm is a labelled historical replay and the 2012 storm a labelled counterfactual. The full list is in [production/ART_BIBLE.md](production/ART_BIBLE.md) §2.

## 5. Tools, accounts and credits

| Tool | What it is used for | How |
|---|---|---|
| **Tripo CLI** `~/.npm-global/bin/tripo` (v0.8.1) | 3D characters and props, auto-rig, exports | Logged in to the user's Professional web plan. See the rules below. |
| [production/tools/tripo_api.py](production/tools/tripo_api.py) | The separate **1,000 API-only credits** | Reads `TRIPO_OPENAPI_KEY` from `~/.zshrc`. |
| **Meshy** | Character rigs and animation clips (rig 5 credits incl. walk + run, 3 per preset clip); game-ready props (Smart Topology `meshy-t2.5`, 15 credits textured) | MCP `meshy` (`@meshy-ai/meshy-mcp-server@0.6.5`, user scope, connected 26 Oct) for animate, status and balance. Rig and remesh need a model URL, so local GLBs go through the REST API as a data URI: `tools/meshy_rig_local.py`, results with `tools/meshy_fetch.py` (key read from `~/.claude.json`, never printed). 1,100 credits a month, more accounts available: don't ration. |
| **ElevenLabs connector** | Concept art (Nano Banana Pro `gemini-3-pro-image`), cutscene video (Seedance 2.5 `bytedance-seedance-v2.5`; the `-us` variants are region-blocked; Veo 3.1 also available), voices (TTS v4), music (v2.5), sound effects | Cutscenes, their references and the 26 Oct prop concepts live on flow `CausC2kFXXiuy3wFDEwH` ("Last Light Academy — Cutscenes"). |
| **Blender 5.2.2** (`/opt/homebrew/bin/blender`) | Clean-up, previews, pose tests, final GLB export | Headless scripts in `production/tools/`. |
| **Codex CLI** | Code review (the user's standing rule: Codex reviews code) | `codex exec -s read-only "<review prompt>"`. `codex review --uncommitted` cannot take a custom prompt. |
| **Antigravity CLI** `agy` (`~/.local/bin/agy`) | UI/frontend, browser testing, visual checks | `agy -p "<task>" --mode plan` for read-only work. |
| **Claude Code Game Studios** v1.2.0 (installed 30 Oct 2026) | Game-dev workflow for Claude Code: 49 studio agents, 74 slash skills (`/start`, `/adopt`, `/setup-engine`, `/design-system`, `/sprint-plan`, `/dev-story`…), hooks and path rules | Lives in `.claude/`, `project.yaml`, `design/` and the studio docs in `docs/`. Its master config is the second half of `CLAUDE.md`; the project rules at the top win on conflict. Next steps: `/setup-engine godot 4.7`, then `/adopt` (our design docs live in `game-design/` and the code in `game/`, not the template's `design/gdd/` and `src/`). |

**Tripo CLI rules (learned the hard way)**
1. `--profile` and `TRIPO_PROFILE` are **ignored** by CLI 0.8.1. Only `tripo config use <name>` switches accounts. `tripo --profile X auth login` would overwrite the default account's login.
2. To add an account (the user runs this, because login is interactive): `tripo config create acct2`, `tripo config use acct2`, `tripo auth login --email <email>`, then `tripo config use default`.
3. The active profile is **global**. Never run jobs on two accounts at the same time. [make_character.sh](production/tools/make_character.sh) pauses itself whenever the active profile is not `default`.
4. Switching rule: move to the next account when the current one has **under 75 credits** (one model + one rig). Always finish with `config use default`.
5. **Never set `TRIPO_API_KEY`** in the shell. The CLI would use it instead of the web login and fail with `authentication failed`. The API key lives in `TRIPO_OPENAPI_KEY`.
6. Always pass `--visibility private` (the default is public).
7. Multiview argument order is `<front> <back> <left> <right>`. "left" is the view showing the character's left side, where they face the viewer's left.
8. The rig command's own download **has no skeleton**. Re-export with `tripo export <project> --operator-id <rig-op> --with-animation`; this is free.
9. The project ID differs from the task ID. Find it with `tripo project list --output-format json` or `tripo project history <project>`.

**Measured costs:** multiview detailed model 55; image-to-model detailed ~55; rig 20; pre-rig check 0; export of any existing project 0; `tripo image -m gemini_3_pro_image_preview` about 20 per image (not free; `-o` takes a file path, not a folder).

**Balances (25 Oct 2026, 23:40):** first web account fully spent (0) and retired: all its projects are downloaded (game assets in `game/assets/`, unused pitch-video models archived). The second web account is now logged in as `default` (2,870 credits on 25 Oct 2026, 15 expiring 6 Nov). The empty `acct2` profile was deleted. API pool 1,000 spendable (plus 2,000 shown as "frozen"). Standard-quality image-to-model costs 30 (detailed 55).

**ElevenLabs:** the connector moved to a new account (about 2.4M credits, the user reloads when needed; do not ration). The old account's flow `7PG0tzH7xlVvnfBGlVFc` is no longer accessible, so references are re-uploaded from `production/concept/`. Costs measured on 26 Oct: Seedance 2.5 at 1080p about 6,265 credits per second (37,590 for 6 s); a Nano Banana Pro image 1,200 to 3,700 depending on how many references are wired.

**Reference nodes on the cutscene flow** (wire them with `connect_from`; never invent node IDs):

| Reference | Node |
|---|---|
| Cadet key frame (STYLE-01) | `PWenOLtPp1Uw7aevaNx7` |
| All five turnarounds (CAST_turnarounds.png) | `KLfNPxr2rPmZY0Cdt7kJ` |
| Ferreira turnaround alone (best for her likeness) | `MSDV7UXayoFrW1gi1GgZ` |
| Alo key frame, no eyes (STYLE-03) | `dAf00fjJBkrRYRBtSXf2` |
| Alo bud / Alo pods | `P0AKEY22KEbv5q2PTlK9` / `JLubBo4V6Z77RWfU4ZH9` |
| 2034 seedling tray | `DQJFfo0y62rw4v8iHqox` |
| Growth chamber / Mission Table / vault case | `02l0n0s0FLGdJQ99332z` / `x7sRibUJ8Slr5GaNDvi0` / `H8NnVoKToMliB8c30EX5` |
| Rover / relief lander / hatch door (3D renders) | `RKHrxGmDiidNO33ann9x` / `XVSEohdOAuW6uTmOQ6w5` / `vQGV89ATe2oBTntRUg73` |
| Commons room (CS-01-A start frame) | `eDhTxygFXTOp3WcTQlZG` |

## 6. Pipeline

**Characters** (one command per character once the turnaround is approved):

**Current cast (v8 sheets, 27 Oct):** Tripo multiview quad model + Tripo Mixamo rig (**65 bones**; Mei **68** with 3 ponytail bones) + 42 Meshy clips retargeted + 2 hold poses = **44 clips (13 looping)**, built by `production/tools/finish_character_v7.sh <name> <height_m> <work_dir>` (body and clips via `build_character_v7.sh`, then toon face, sleeve patches, Mei's ponytail bones, hold poses); details in [HANDOFF.md](HANDOFF.md) "READ THIS FIRST". The per-character targets are in [production/manifest/characters.csv](production/manifest/characters.csv). Steps 3 and 5 below are the 25–26 Oct pipeline (78-bone Tripo rig, then the 24-bone Meshy rig with 25 clips), kept as history.

1. Concept: a style key frame plus a four-view turnaround sheet (Nano Banana Pro, flat #D9D9D9 background, A-pose), in the same layout as Kai's sheet.
2. `python3 production/tools/split_turnaround.py <sheet.png> <out>/views front,right,back,left`: splits by background colour, not equal quarters.
3. `production/tools/make_character.sh <Name> <height_m>`: Tripo multiview (H3.1, detailed, PBR, private), then pre-rig check, then rig (v1.0-20240301 biped, 78 bones with fingers, twist and eye bones), then re-export with the skeleton, then Blender clean-up, then previews and pose test.
4. Review `models/final/CH_<Name>/preview/*.png`, especially the pose test (arm raised, leg lifted, spine and head turned: skin must not tear).
5. Animation (26 Oct, all five cast): re-rig with Meshy and add the clip set. `blender -b -P production/tools/strip_rig.py -- <final.glb> <static.glb>`, `python3 production/tools/meshy_rig_local.py <static.glb> <height_m>`, `meshy_animate` (MCP) with the clip ids listed at the end of this step, `python3 production/tools/meshy_fetch.py rigging|animations <task> <dir>`, then `blender -b -P production/tools/assemble_character.py -- rigged_character.glb <final.glb> walking.glb running.glb clips1.glb clips2.glb`. Assembly takes mesh and 4K PBR from the rigged model (clip files carry base colour only), renames clips (looping ones end `_loop`, which Godot imports as loops) and bakes Meshy's 0.01 armature scale into metres (`tools/glb_unscale_armature.py`). Check every clip with `blender -b -P production/tools/render_anim.py -- <final.glb> <dir> --action all`. Clip set (19): Walk, Run, Idle (lib 243), IdleAlt (249), Breathe (336), Listen (47), Talk (313), SitIdle (32 F / 33 M), LookAround (337), Agree (25), OpenDoor (285), PickUp (274 F / 276 M), KneelStand (365), Wave (290), Cheer (303), Drink (342), Push (259), SitDown (58), StandUp (52 F / 53 M). Library id 0 "Idle" is a fighter's stance: not used. Story motions (Meshy text-to-motion, prime, applied with `meshy_animate` motion_task_id, named with `Name=file.glb` in assembly): Pollinate, Water, Inspect, Type, Repair; plus Carry_loop (library 611, in place). Prompts in AI_PROMPT_LOG.md. Gate spec: 25 clips, 10 looping.

**Clean-up standard** ([blender_cleanup.py](production/tools/blender_cleanup.py)): weld split seams, then decimate **before** the Armature modifier (so skin weights survive), rotate −90° (Tripo faces +X), scale to height, pivot at the feet, apply transforms, export GLB with Y up. Its smoke test is `production/tools/test_blender_cleanup.sh`.

**Props:** reuse an existing Tripo project first (export is free), then Meshy Smart Topology, then Tripo image-to-3D. Same clean-up with `--tris` from the art bible (hero props 15–40k, small props 1–5k) and no `--rigged`; use `--height` for standing objects and `--longest` for objects lying flat. Replace any screen with a live UI material; no text is baked into models.
- New props: one concept image per prop (single object, three-quarter view, flat #D9D9D9 background), listed in a manifest such as [production/manifest/tripo_props_batch1.csv](production/manifest/tripo_props_batch1.csv), then `RESERVE=<credits to keep> production/tools/make_prop.sh <manifest>`. Resumable; stops before the balance drops under the reserve.
- Reused props: [production/manifest/reuse_props.csv](production/manifest/reuse_props.csv) maps each exported pitch-video model to its game role and real size.

**Godot:** the project lives in [game/](game/) (Godot 4.7.2, Forward+). `production/tools/sync_to_godot.sh` copies every finished GLB into its own folder `game/assets/<category>/<Name>/`, imports headless, then runs the quality gate. Textures stay embedded in the GLB (project import default `gltf/embedded_image_handling = 2`, Basis Universal), so each folder holds only `<Name>.glb` and `<Name>.glb.import` and textures are never stored twice. Commit `*.import` files; `game/.godot/` is cache.

**Quality gate (every new or changed asset, no exceptions):**
1. Automated: `production/tools/verify_gate.py` (run by the sync) compares what Godot imports with the asset's manifest row: imports with a mesh, triangles within budget, largest texture within budget, standing on the floor (lowest point y = 0 ± 1 cm), real size within 2 % (height or longest side), characters have the bone count and clips of their manifest row (current cast: 65 bones, Mei 68; 44 clips, 13 looping). Results: [production/review/asset_verification.md](production/review/asset_verification.md).
2. Visual: review the asset's renders (contact sheet in `production/review/`) against the concept and the art bible: right silhouette, colours, no faces on plants, no baked text, no broken geometry, nothing missing from the concept. Codex (`gpt-6-astra`, high) gives the independent second opinion. Results: [production/review/visual_review.md](production/review/visual_review.md).
3. Only assets that pass both are marked `verified` in the registry.

**Audio and cutscenes for Godot:** music and voice as `.ogg` (Vorbis), short effects `.ogg` or `.wav`; cutscenes must be **Ogg Theora `.ogv`**, the only video format Godot 4 plays. Masters (MP4, WAV) stay in `production/`.

**Keep it clean (user rule):** after any task, delete rejected variants, duplicates, temp files and caches; keep regenerable or large intermediates in the git-ignored `production/models/`; heavy media go through Git LFS ([.gitattributes](.gitattributes)); check `git status` shows no junk. Never delete with broad patterns (`pkill -f`, `rm -rf $VAR`); a safety hook blocks the latter.

**Previews:** `blender -b -P production/tools/render_preview.py -- <glb> <prefix>` renders front, side, back and ¾ views and prints triangle count, size, textures and bones. The glTF importer adds an "Icosphere" bone-display shape on import; it is not in the file.

**Baked-in details** (name-tag letters, a fake screen readout): `blender -b -P production/tools/blank_texture_region.py -- <glb> x0 y0 x1 y1 --res 1600 --fill <out.glb>` paints over a pixel box of the front preview, flattens the normal map there, and with `--flatten` flattens the mesh; `--screen 12` also adds a separate flat "Screen" material slot that Godot can drive with a live UI texture (PR_Dosimeter, CH_Ferreira).

**Cutscenes** (section 9), one shot per row of [shots.csv](production/cutscenes/shots.csv):
1. Start frame: Nano Banana Pro with the approved references wired in (table above), two takes. Until the environment kit exists there is no 3D scene to render, so frames are generated; once rooms exist, a Blender render can replace them.
2. Review the frame against the art bible before animating: right cast (all who should be there, each once), adult proportions (the cadets are 19–20, never child-sized), Ferreira's dark hair greying only at the temples (image models drift her to grey: say "jet-black hair"), role-colour tabs (Kai orange, never gold), flag on the left shoulder of every suit, cadets and Ferreira alike (if a frame has all flags on the right and no text, mirror it; image models confuse left and right, so in an edit name the sleeve by its neighbour, e.g. "the arm next to the commander", never "left"), blank name tags, black sky, grey regolith (never beige, no golden sky through windows), no stars over a sunlit surface, no visible light beams in vacuum, no dust haze or puffs (whatever is in the frame gets animated, so clean the frame first), no plant faces, no readable text. Pin the pick with `creative_add_flow_asset_node`.
   - **Before any image edit, pin the exact take first** and wire that pinned node: an edit wired to a generation node uses whichever take is active there, which is how CS-17-B once got the wrong suits.
3. Seedance 2.5 video node wired to `start_frame`: `resolution 1080p`, `duration_secs` from shots.csv, `generate_audio false`; the prompt describes motion only and repeats "consistent characters, no deformation". Describe what you want, not what to avoid: "no dust trail" still produced dust, so write "the wheels press crisp tread tracks, the ground around them stays perfectly clear".
4. `production/tools/intake_shot.sh <shot> '<content_url>'` saves `production/cutscenes/masters/<shot>.mp4` and a start/middle/end strip in `production/cutscenes/review/`. Check the strip (and a 6-frame grid when a story beat is in the motion), then set `status` and `elevenlabs_ids` in shots.csv and log the prompts in AI_PROMPT_LOG.md. Stars left in a sunlit shot's sky: `python3 production/tools/clear_stars.py <master> <out> [--rows 0.62]` removes them in post (check the mask first with `--debug <png> --at <frame>`; it keeps 10-bit HEVC and BT.709 tags), as done for CS-17-A. `--grade-sky 0.45` also pulls an atmospheric-looking glow in the sky down to black, leaving a tight glare round the Sun (CS-02-A).
5. **v7 assembly (27 Oct):** Seedance 2.5 at 720p (about 2,800 credits/s against 6,265 at 1080p; reference images cannot be combined with a start frame), eleven_v4 voice lines and an eleven_music_v2_5 cue per cutscene, then a spec in `production/cutscenes/v7/src/CS-xx.json` and `python3 production/tools/compose_cutscene.py <spec>` (dissolves, chapter card, wrapped speaker captions, music ducked under lines, radio band-pass for Earth-link and recorded voices). For Godot: `ffmpeg -i <master.mp4> -vf fps=24,scale=1152:648 -q:v 2 <frames>/%05d.jpg`, then `Godot --path game --resolution 1152x648 --write-movie game/assets/cutscenes/<name>.ogv --fixed-fps 24 -s production/tools/ogv_writer.gd -- <frames> <master>.wav` (Godot's Movie Maker is the only Theora encoder here; Homebrew ffmpeg has none).
6. Older plan: voice from ElevenLabs designed voices (speech is never baked into generated video; on-screen speakers need lip-sync), music and effects, English captions, then `.ogv` for Godot. Earth-side shots (Noor's rooftop, Rao's desk) may be fully generated.

## 7. Files and naming

```text
PRODUCTION_HANDBOOK.md       this file
CLAUDE.md, AGENTS.md         short rules for AI agents, pointing here
game/                        Godot 4.7.2 project (Forward+)
  assets/<category>/<Name>/  game-ready assets, one folder each (see game/assets/README.md)
  assets/audio/{music,sfx,voice/<Speaker>}/, assets/cutscenes/, assets/ui/
  tools/verify_assets.gd     headless asset report used by the quality gate
production/                  sources, plans and tools (see production/README.md)
  ASSET_REGISTRY.csv         every asset, made or planned
  ART_BIBLE.md, AI_PROMPT_LOG.md
  manifest/                  characters, props, reuse, planned assets, scene index
  concept/                   approved concept art only
  audio/                     vo_lines.csv, music_cues.csv, sfx_list.csv
  cutscenes/                 shots.csv (Seedance prompts per shot)
  review/                    asset_verification.md, visual_review.md, contact sheets
  tools/                     pipeline scripts, all headless
  models/                    git-ignored staging: raw/, reuse/, final/
```

The retired first Tripo account's unused downloads (pitch-video astronauts in the old suit, kiosk, chest, dome, old plants) are archived outside the repo at `~/nasa-space-apps-2026-archive/tripo-account1/`.

Prefixes: `CH_` character, `PL_` plant, `PR_` prop, `EN_` environment, `VH_` vehicle, `FX_` effect, `CS_` cutscene, `VO_`/`SFX_`/`MUS_` audio. Textures are `T_<Asset>_<BaseColor|Normal|ORM|Emissive>`. Units are metres, Y up in Godot, pivots at the base.

**Git:** commit only when the user asks. Commits are authored as **sadmanqt** (the user's GitHub account) with **no Claude or Codex co-author lines** (user rule). Final GLBs and videos go through Git LFS (set up before the first model commit). Raw downloads stay out of git.

## 8. Asset master list (all 8 chapters, from the final story)

Status: ✅ final · 🟡 in progress · ♻️ reuse candidate already exported · ⬜ not started. "A-xx" refers to [game-design/14_ASSET_PRODUCTION_LIST.md](game-design/14_ASSET_PRODUCTION_LIST.md). Scene references use the final IDs.

### 8.1 Characters

| ID | Asset | Chapters | Status |
|---|---|---|---|
| CH_Kai (A-01) | v7 anime (v8 sheets): Tripo quad model, 1.74 m, ~58k tris, Mixamo 65-bone rig, 44 clips, toon face layers (no brows) | all | ✅ `game/assets/characters/CH_Kai/` (27 Oct) |
| CH_Amara (A-02) | v7 anime (v8 sheets), 1.72 m, 65 bones, 44 clips, toon face | all | ✅ (27 Oct) |
| CH_Mei (A-03) | v7 anime (v8 sheets), 1.60 m, 68 bones (65 + 3 ponytail), 44 clips, toon face | all | ✅ (27 Oct) |
| CH_Rafi (A-04) | v7 anime (v8 sheets), 1.84 m, 65 bones, 44 clips, toon face | all | ✅ (27 Oct) |
| CH_Ferreira (A-07) | v7 anime (v8 sheets), 1.68 m, 65 bones, 44 clips, toon face; Earth duty-layer variant still to make | all | ✅ suit coverall (27 Oct); ⬜ duty layer |
| Cadet variants | Helmet per cadet (role stripe); indoor navy duty coverall | all | ✅ indoor v7 coveralls; one helmet installed; ⬜ fitted role variants / EVA outfits |
| Rao (A-61) | Bust/portrait with headset at an Earth desk (screen only) | CH01–08 | 🟡 v7 portrait installed at `game/assets/ui/portraits/CH_Rao_screen.png`; screen/voice integration pending |
| Noor (A-09) | Archive portrait (2034, younger), present-day portrait, live rooftop scene in Dhaka for CH08-S10 | CH05–08 | 🟡 both v7 portraits installed in `game/assets/ui/portraits/`; v7 rooftop/live-call integration pending |
| Voices only | Kai's family (CH06-S08 audio), 2034 Engineer recording (CH02-S10) | — | ⬜ voice |

### 8.2 Plants (no eyes or faces, ever)

| ID | Asset | Scenes | Status |
|---|---|---|---|
| PL_Alo (A-05) | Seed, sprout, bud, first bloom, flowering, pollinated, pods, mature-dry; frost and thirst stress states; sway shader | CH01-S03 → CH03-S10 | 🟡 bud, bloom and pods installed; early/stress states, sway and toon treatment pending |
| PR_PressedPetal (A-30) | Alo's archived petal in a dated sleeve | CH03-S10 → CH08-S12 | ⬜ |
| PL_Tara (A-06) | Same stages, green stem, own label | CH01-S04 → CH03 | 🟡 bloom installed; other stages, own label and toon treatment pending |
| PL_Descendants | 12-position tray; CH04 sample of 7 purple + 5 green stems; renewing mixed final garden | CH03-S11 → CH08-S12 | ⬜ |
| PL_ZeroSeedlings | Frozen 2034 trays: young unflowered seedlings with curled leaves only | CH03-S06/S07, CH05-S04 | 🟡 `PL_ZeroSeedlingTray` installed; toon/staging pending |
| PL_Cotton (A-41) | Seed, sprout, young plant, alive at first light (no boll) | CH05-S12 → CH08-S12 | 🟡 young plant installed; seed/sprout/cassette and toon pending |
| PL_CropRack (A-14) | Edible crop rack (gameplay food layer) | CH01+ | 🟡 `PL_CropRack` installed; toon and gameplay integration pending |

### 8.3 Environments

| ID | Location | Scenes | Status |
|---|---|---|---|
| EN_Commons (A-10) | Mission Table, Earth console/screen, lockers, galley; 4 then 5 mugs | throughout | ⬜ |
| EN_Kit (A-11) | Modular habitat walls, floors, 1.2 m doors, lights, corridors | throughout | ⬜ (♻️ space tunnel, viewport, light capsule) |
| EN_ServiceRooms (LOC-02) | Power room (battery jar, heater console, F2 feeder, hand-light locker, eclipse allocation board, protected-bus test panel); atmosphere room and service corridor (oxygen tank, independent gauge, three diagnostic taps, isolation valves, garden spur) | CH01, CH03, CH05, CH06 | ⬜ (♻️ control console, industrial control panel, machinery) |
| EN_Garden (LOC-03) | Exterior pressurised test chamber with glove ports and **viewing shutter**; Tara indoor reference bay; botanical bench; paired care stations; drying bench; planting rack; reserve store; lineage board; dry quarantine glovebox | CH01–08 | ⬜ |
| EN_SafeRoom (A-13) | Five seats, water wall, four supply-bundle slots, hatch, roll-call board, response controls, archive player, seed-case latch | CH01, CH07 | ⬜ (♻️ capsule bunk bed, cargo crates) |
| EN_Airlock (A-18) | Double interlock, suit lockers, sealed pollen pass-through | CH02, CH04, CH05, CH08 | ⬜ |
| EN_Garage (A-08) | Rover bay, cargo rack, departure boards, landing-pad camera view | CH04, CH05, CH07, CH08 | ⬜ |
| EN_ZeroAnnex (A-27) | N.R. hatch under the floor cover, viewing port, cold annex, warm-side support station, chart archive, map pouch | CH03 | ⬜ (♻️ vault door) |
| EN_Fabrication | Local fabrication bench and route simulator | CH07-S11 | ⬜ |
| EN_Exterior (A-21/A-52) | Mast courtyard, twin solar masts, horizon, landing pad | CH01, CH04, CH05, CH08 | ⬜ (♻️ solar panel tower) |
| EN_ColdTrap (A-36/A-10) | Ridge road with three beacons, dry reference plate, sample points, vault shelf | CH04-S03 → S09 | ⬜ |
| EN_RelayRoad (A-45) | 120 km road as five short playable segments; repeaters R1–R3; marker-two service pad | CH08-S02 → S06, S11 | ⬜ |
| EN_Malapert (A-44) | Summit relay: controller housing, isolator, local antenna, Earth dish, tether platform | CH08-S06 → S10 | ⬜ |
| EN_NoorRooftop (A-09) | Modest Dhaka rooftop with plants at night (screen scene) | CH08-S10, S12 | ⬜ |
| EN_EarthDesk (A-61) | Rao's compact Earth control desk (screen) | CH01–08 | ⬜ |

### 8.4 Props by chapter

- **CH01:** power console and battery jar (A-12), air console and oxygen tank, mast status panel, charter and emergency card, four crew name tokens, practice fault panel, seed packet "ALO / N." (A-20), calibration bench, moisture probe and reference sample, two planting cassettes (A-15), Kai's hand light and equipment-board spot (A-34), horizon/timeline display, water wall panels, valve and reservoir (A-16, ♻️ valve), supply bundles ×4 (A-22, ♻️ cargo crates), exposure instrument (A-29, ♻️ dosimeter), horticulture recorder (A-19, ♻️ vintage computer), four mugs.
- **CH02:** origami paper bee, brushes A and B, closed pollen carrier, transfer interlock, nonliving flower model, magnified flower diagrams, seven-date care strip with bee stamps, recorder service sticker over the serial plate, 2034 trial-stage chart, evidence board, Earth-link transmit console, the trembling cup, displaced service cover, brace-zone markers.
- **CH03:** independent mechanical gauge (A-25), three diagnostic taps, piping diagram, isolation valves and clamp (A-26), annex floor cover and N.R. hatch, camera viewing port, growth chart, map pouch, maturity camera, drying profile display, contained harvest tray and counting wells, reserve container (30), 12-position planting tray (A-28).
- **CH04:** descendant rack and prediction notebook, pressurised three-seat rover (A-31, ♻️ space rover), consumables manifest, route cards A/B/C, three beacons (A-33), ice scanner (A-32), sealed sample holder (A-35), insulated vault case with a 12-well inner container (A-37), probe, sleeve and cradle, rover cargo mount, lid inscription, fifth mug, prepared locker.
- **CH05:** relief lander on the landing camera (A-39, ♻️ lunar lander/module), relief cargo crates, replacement relay-controller crate, atmosphere panel with a visible handwritten correction, four primary records (relay fault report, greenhouse note, evacuation order, ascent manifest), impact-camera monitor frames (A-40), panel-cleaning kit, spur patch kit, signed identity page, message composer, cotton cassette; Dust Shield / Whipple bumper visible upgrade variants.
- **CH06:** five segment cards and protected-service board, guide-light branch, decorative floods, protected-bus test panel and feeder F2 (A-42), filtered remote camera and monitor with a labelled Earth-limb inset, family audio-call UI, monitoring calendar, active-region solar image.
- **CH07:** five shelter seat markers, seed case with two 15-seed compartments, water-wall valve diagram, local telemetry displays, archive player, damaged external uplink feedthrough (A-43), local network diagnostic panel, spare battery, repeater site models, departure boards.
- **CH08:** rover loadout (controller, battery spare, service diagram), route-planning console, repeater battery bay, Malapert controller housing and isolator, local and Earth dish controls, ALO42 data-check panel, shared expedition photo (A-46), MARS drawer post-credit still (A-47).

### 8.5 Animation, UI and audio

- **Animation (A-48–A-51):** locomotion (walk, run, idle, turn, brace, sit), care hands (plant, brush, scan, count seeds, sleeve petal), repair and vehicle (valve, clamp, isolate, connector, battery swap, enter rover, tether), gestures (offer lamp, place mug, roll-call answer, grief pause, group photo). Tripo presets (v1.0 rig, up to 5 per call) or retargeting in Godot.
- **UI (A-53/A-54):** HUD, Mission Table planning and forecast/preview, decision review, journal (Mission/People/Garden/Evidence/Science), evidence board, debrief, printable Class-mode role cards, settings and accessibility (captions, 150% text, timer-free). English only; icons always paired with words.
- **Audio (A-55–A-57):** designed ElevenLabs voices for every speaking character (Noor has a younger archive voice and an older live voice); sound effects (fans, valves, water, doors, suit, rover, alarms; none airborne outside); score cues CUE-01 to CUE-12. Captions must carry the full story without VO.

## 9. Cutscene master list (final scene IDs)

Rules from the cinematic guide and the final story: cutscenes are short, embedded in play and skippable; they never solve a puzzle and never replace a safety check; **do not lengthen a cutscene to pretend it is playable time**. **User change, 27 Oct:** cutscenes are longer than the lengths below (v7 runs 40-50 s) to carry more of the story; still no puzzle or safety-check content inside them. Dialogue is the scene's own lines from STORY_FULL.md, word for word.

| CS ID | Was | Final scene | Beat | Length | Make with |
|---|---|---|---|---|---|
| CS-01 | CIN-01 | EX-CH01-S01 | Arrival at Aurora; Ferreira on the Earth screen | 20–30 s | Seedance from a 3D start frame |
| CS-02 | CIN-02 | EX-CH01-S09 | Last light; masts stop; Earth link greys out | 25–40 s | In-engine plus a Seedance exterior plate |
| CS-03 | CIN-03 | EX-CH01-S12 | Chamber check, shutter opens, Alo's first flower; N.'s stored message | 25–35 s | Seedance (macro plant shot) plus in-engine |
| CS-04 | new | EX-CH02-S12 | The cup trembles; four crew brace; the pressure warning changes | 15–20 s | In-engine |
| CS-05 | CIN-04 | EX-CH03-S07 | Suited entry to the 2034 annex: unflowered seedlings only (**no buds**, overriding the old CIN-04 text) | 20–30 s | Seedance from a 3D start frame |
| CS-06 | CIN-05 | EX-CH03-S10 | Forty-two seeds counted; Mei's grief; nobody leaves | 45–60 s | In-engine (counting is interactive) |
| CS-07 | CIN-06 | EX-CH04-S06 | Headlights find a manufactured corner: the vault | 15–20 s | Seedance exterior from a 3D start frame |
| CS-08 | new | EX-CH05-S01 | Relief lander on the landing camera; Ferreira at the airlock; the fifth mug | 20–30 s | Seedance (lander exterior) plus in-engine |
| CS-09 | CIN-07 | EX-CH05-S05 | Ferreira seated level with the crew: "I was the engineer who could not fix the radio." | 35–50 s | In-engine (static shared frame, no music) |
| CS-10 | CIN-08 | EX-CH05-S10 | Signed page → Noor's portrait → faces; consent line | 35–45 s | In-engine plus Noor portrait art |
| CS-11 | CIN-09 | EX-CH06-S07 | Red ring on the filtered camera with the labelled Earth-limb diagram | 20–30 s | Seedance monitor footage plus a UI overlay |
| CS-12 | CIN-10 | EX-CH06-S10 | Camera feed drops, the guide light stays on; Kai isolates F2 with Rafi on the channel | 15–25 s | In-engine |
| CS-13 | CIN-11 | EX-CH07-S07 | Noor's last log in the storm lull; Mei holds the petal near the seed case | 20–30 s | In-engine (no flashback) |
| CS-14 | CIN-12 | EX-CH08-S01 | Three in the rover, two at home; the airlock seals | 20–30 s | Seedance exterior plus cabin |
| CS-15 | CIN-13 | EX-CH08-S10 | "Hello, Aurora. This is Noor." Cuts between the summit cabin, Aurora and the Dhaka rooftop | 35–50 s | Seedance (rooftop fully generated) plus in-engine |
| CS-16 | new | EX-CH08-S11 | The same road home; five crew at Aurora at 03:00 | 15–20 s | Seedance exterior plus in-engine |
| CS-17 | CIN-14 | EX-CH08-S12 | Shutter at first light: descendant garden, cotton alive, petal beside the label; the shared photo | 45–70 s | Seedance plus in-engine |
| CS-18 | — | post-credits | Closed MARS drawer still (no new quest) | 5 s | Still render |

Optional opening (from the gameplay entry flow): mustard fields to the Moon chamber, 20–30 s, with no claim that Alo existed before the story.

## 10. Status (latest first)

**4 Nov 2026 — P-05 clock decision (Atik):** preserve final story dates; the four 7.2-hour P-05 phases are an **abstract resource budget**, not elapsed time added to scenario_datetime. Atik explicitly selected “Keep story dates; abstract phase budget”. M3-80 is reopened under atik/codex; source numbers and story timestamps remain intact.

**4 Nov 2026 — Later-ledger source reconciliation (board M3-80, Atik/Codex):** blocked on the P-05 clock contract: three unresolved 7.2-hour phases from May 6 22:05 end May 7 19:41, while the final story verifies repair before dawn May 7. The E18/A3/H6/C8/R13.2 arithmetic reproduces correctly. An abstract-budget versus elapsed-time decision has been requested; no later-ledger runtime completion is claimed. Counterexample and remaining work: [M3-80.md](production/review/execution/M3-80.md).

**4 Nov 2026 — Saved discoveries and caption gates (board M1-26, Atik/Codex):** successful physical operations now atomically acquire canonical scene records with observed operation labels. Journal queries, JSON checkpoints, identity/relay knowledge flags and the acknowledged-only backlog use that saved state. Campaign captions and director acknowledgements enforce DialogueService requirements; see [M1-26.md](production/review/execution/M1-26.md).

**4 Nov 2026 — Crew presence (board M1-17, Atik/Codex):** roster-bound cached bodies now accompany the authored viewpoint, reuse the player character setup, block movement, listen/talk/look at the displayed speaker and pause together. Safe Room seating and Earth-screen portraits are integrated; Ferreira’s portrait derives from her approved GLB. See [M1-17.md](production/review/execution/M1-17.md) for checks, screenshots and the separate EVA/environment/contact limits.

**4 Nov 2026 — Outpost Status and shared forecasts (board M1-28, Atik/Codex):** four persistent HUD cards show E, A/W, shelter S/exposure Z and crops C/rations R from the director query. Shelter uses the simulation’s existing capped upgrade-aware calculation; display thresholds live in JSON. Real-route forecasts run on a restored checkpoint copy and never commit live progress. Four meters remain visible above reflowing reading panels at 150% text; details, screenshots and verification: [M1-28.md](production/review/execution/M1-28.md). Interactive puzzle choices, learner/device/controller review and physical screen-reader checks remain separate work.

**4 Nov 2026 — portable export candidates (board M1-20, Atik/Codex):** version `0.1.0-preview.20261104` has Windows x86_64, unsigned universal macOS and browser-feasibility presets. Raw GLB bytes and offline JSON are preserved in the pack, development scenes/tools are excluded, and the native binary’s isolated export diagnostic passes on local macOS. Reproducible scripts, clean-runner workflow, artifact checks and remaining publication/QA gates: [release_2026-11-04.md](production/qa/release_2026-11-04.md). Candidates are in ignored `builds/`; no public Release or browser hosting is approved yet.

**4 Nov 2026 — visible habitat greybox (board M1-01, Atik/Codex):** LOC-01–LOC-06 now use authored room JSON for prop/target/companion/player transforms, visible matte toon floors/walls/ceilings and practical lighting. The courtyard has grey ground, black sky, a low hard Sun and no atmospheric fill/fog; Earth remains omitted pending verified local geometry. The production interaction prompt and fitted highlight follow the same in-range, in-view target as E. Six player-camera room screenshots, the campaign prompt and verification limits: [M1-01.md](production/review/execution/M1-01.md). Final environment art, EVA costumes, prop collision and door traversal remain separate board tasks.

**4 Nov 2026 — retired unreachable commissioning slice (board M0-03, Atik/Codex):** removed the old three-scene controller/HUD/rules/content and their three dedicated suites, the full loader’s slice adapters and Chapter2Route’s uncalled preview helper. Production now keeps only `scripts/save/legacy_save.gd` for the old slot path and explicit deletion after New Expedition confirmation. Full-campaign/UI/save tests remain; details and current results: [M0-03.md](production/review/execution/M0-03.md).

**4 Nov 2026 — Data Card runtime (board M0-15, Atik/Codex):** `ScienceData` reads all 28 offline fixtures and maps P-01–P-16 to source cards, with content validation that rejects missing provenance. PuzzleHost, outcome panels and the Journal share that lookup; the campaign HUD opens pause-safe Data Cards with a plain-language Aurora takeaway, a fixture-derived chart, measured inputs, computations, limitations and citations. Keyboard/controller Back restores focus and 150% text scrolls. Current evidence and test results: [M0-15.md](production/review/execution/M0-15.md).

**4 Nov 2026 — NASA data map, offline fixtures, credits (board M0-13, M0-14, M0-16):** [docs/SCIENCE_AND_DATA.md](docs/SCIENCE_AND_DATA.md) §B now maps 28 verified NASA and partner sources to every puzzle P-01–P-16 (B3 lists 15 numbers no dataset supports, with proposals; 08 is unchanged). `production/tools/fetch_nasa_data.py` wrote 28 small offline fixtures and `puzzle_sources.json` to `game/resources/data/nasa/` (no keys; `--check` passes). [CREDITS.md](CREDITS.md) credits every file in `game/assets`; no font files exist (the game uses Godot's built-in Open Sans, OFL). Still open: the official Resources tab (M0-12), docs/TEAM.md, and confirming each AI service's terms.

**3 Nov 2026 (night) — documentation drift and AI-use disclosure (board M0-18, M0-17):** README, GAMEPLAY_DESIGN_FINAL, STORY_FINAL, CAMPAIGN_SEASON1, 10_GAMEPLAY_SYSTEMS, HANDOFF, the execution notes and this handbook now agree with canon (English only, faceless plants, Forward+ with a Compatibility fallback, CH4 rover 100/reserve 30, CH8 home air A8, 32 missions, v8 cast 65/68 bones and 44 clips); 717 split words in `execution/*.md` repaired; legacy-id game-design files carry a "historical ids" note; [shots.csv](production/cutscenes/shots.csv) rows are `archived-realistic`. [docs/AI_USE.md](docs/AI_USE.md) is the text for the project page's "Use of AI" field and [AI_PROMPT_LOG.md](production/AI_PROMPT_LOG.md) now covers 27 Oct to 3 Nov. Documentation only; no game code, assets or numbers changed.

**3 Nov 2026 (evening) — rules check, bug hunt and team board:** the official Bangladesh Participants Guide was read in full and checked against the project ([docs/competition-rules.md](docs/competition-rules.md) §H): main gaps are NASA-data-first traceability, the AI-use log (stops at 27 Oct), LICENSE/credits, written early-start permission, and a build that lets the player make the decisions. A Codex bug hunt ([production/review/BUGHUNT_2026-11-03.md](production/review/BUGHUNT_2026-11-03.md)) found no P0 but ten P1 defects; most important, **Chapter 2 is not playable in the production controller** (no operations, B01; the Chapter 1 handoff cannot fund pollination, B03; Chapter 2 saves cannot restore, B02) although its fixture test passes. Fixes are task M0-02. New `game/tools/run_tests.sh` runs every suite and only passes a suite that prints a passing line and exits 0 (Godot exits 0 when a test script fails to parse: on this Mac 10 of 25 suites had silently not loaded because the gitignored class cache was stale). All remaining work is now on the team board with full prompts (116 tasks, M0–M3); every teammate's AI follows [production/plan/GO_NEXT.md](production/plan/GO_NEXT.md) when told "go next".

**3 Nov 2026 — verified later-campaign route checkpoint:** the production controller now selects and restores Chapter 1, Chapter 2 and the shared Chapter 3–8 route. Chapter 2 has ordered P-03/P-04 physical gates and primitive puzzle snapshots; Chapters 3–8 cover all 72 remaining scenes with receipt-validated P-05–P-16 gates, room targets, chapter boundaries and EX-CH08-S12 campaign completion. Fresh Godot 4.7.2 headless results: Chapter 2 **94/94**, Chapters 3–8 **452/452**, later runtime transition **7/7**, production session **8/8**, Chapter 1 flow **90/90**, UI **32/32**, logic **34/34**, save recovery **34/34**, Worker A **101/101**, Worker B **187/187**, Worker C **577/577**, boot **4/4** and content **9/9**. This is a functional route checkpoint (committed and pushed in `ff09cfd`), not final visual, learner, audio, device, export or release QA. The later bug hunt shows the Chapter 2 fixture bypasses the real handoff (B01–B03).

**3 Nov 2026 — commissioning result HUD:** fixed the numeric revision formatting that stopped `Confirm Plan` at `slice_hud.gd:180`. The commissioning regression now renders the actual result HUD after all three decisions. Fresh Godot 4.7 headless results: commissioning 15, boot 4 and content/UI 547 checks, all passing with no engine errors. Visual playthrough and export remain unverified.

**3 Nov 2026 — systems/content/world checkpoint:** the bootstrap now has a validated systems foundation (`production/review/execution/WORKER_A_SYSTEMS.md`), the full canonical content/dialogue catalog and accessible presentation services (`WORKER_C_CONTENT.md`), and reusable Chapter 1 room/navigation/interaction/roster/mission adapters. Worker A passes 101 focused checks; Worker C passes 577; Worker B passes 187 checks across the complete 12-scene Chapter 1 traversal and CH02 readiness. The project still does not claim remaining chapters, runtime audio, visual/learner review or export as complete.
**3 Nov 2026 — production boot/session checkpoint:** `main.gd` launches `chapter1_campaign.tscn`, wiring `CampaignDirector`, the selected chapter route, full catalog validation, accessible campaign HUD/panels and versioned `SaveService`. The commissioning scene and legacy save remain available as compatibility paths. Fresh headless session smoke: **8/8 checks, exit code 0**; the route fixtures and regression counts are recorded in the later-campaign entry above. Visual playthrough, learner/controller review, Windows export, runtime audio and final credits presentation remain open.

**27 Oct — execution documentation:** `execution/` now contains 300 separate task prompts plus shared contracts, current-state notes, phased scheduling, ownership/dependency guidance and coverage/validation indexes. The prompts cover the 75 registry assets, 22 additional required families, all 32 missions/96 scenes/385 lines, 16 puzzles, 16 UI families, 18 cutscenes, speaker groups, music/SFX, source evidence, upgrades, endings, animation, QA and release. This is a documentation deliverable; it does not mark the implementation tasks complete or change approved story/art/numeric decisions. Start with [execution/00_START_HERE.md](execution/00_START_HERE.md). No asset generation, credit spend, commit or push is part of creating this pack.

**27 Oct late (walks, showcase, cutscenes v7):**
- Walks: the user approved Ferreira's walk, so every character's `Walk_loop` is now their own Meshy rig's plain walk (`walking.glb`, "walking_man"), passed first in `tools/build_character_v7.sh`. The SprintStop and RunToWalk one-shots are no longer played (they flailed the arms); gait cycles are sampled through cubic rotation curves.
- Showcase for the team: `game/scenes/dev/asset_showcase.tscn` shows every asset in rows; 1-5/Tab switch the playable character, H cycles hold modes, C opens the cutscene list, which plays every `.ogv` in `game/assets/cutscenes/` (`game/tools/test_asset_showcase.gd`, 369 checks).
- Props and holds pass (27 Oct, 20:40): every exhibit re-rendered close up in the showcase. Fixes: (1) runtime-loaded GLB textures had no mipmaps (distant detail sparkled); `ToonMaterials` now builds them once per texture. (2) `toon_world.gdshader` cel-flattens the props' photoreal grime (faint brightness noise pulled to its surroundings; strong details and hue kept; `detail_flatten`, `flatten_lod`). (3) Showcase labels are placards on each plinth's front edge instead of floating in front of the models. (4) `HoldRight_pose` was a fist (3.5 cm handle): `tools/add_hold_poses.py` now opens HandGrip toward HandRelaxed per character until the curl wraps the 6.6 cm hand-light barrel; all five rebuilt from the v8 build intermediates and synced (gate 49/49). `HeldProp` RIGHT runs the handle across the palm through the centre of the finger curl, lamp out of the thumb side; BOX holds `PR_VaultCase` at real size with the palms on its sides (the supply-bundle stack was 1.6 m tall and covered the face). Showcase test 369, player 105, review 447, all suites pass. Codex review still owed: its CLI is logged out (401).
- Cutscenes v7 (anime): CS-01 Arrival 47.2 s, CS-02 The Horizon Closes One Door 41.1 s, CS-03 Alo Needs a Friend 44.6 s, built and playing in the showcase. Masters in `production/cutscenes/v7/`, sources and specs in `production/cutscenes/v7/src/`; pipeline in section 6. CS-02-C, CS-03-B and CS-03-C are slow push-ins over their start frames: their Seedance nodes on flow `e31hXPqSGnCFtVtzf44D` were refused when the ElevenLabs credits ran out (about 7,000 left). Re-run those nodes, then CS-04 to CS-18, once the user has credits: about 2M credits at 720p. Top-ups are the user's decision; never assume one.

**27 Oct Codex hold/review/readiness pass:** completed `PlayerAnimation.Hold.NONE/BOX/RIGHT` and `PlayerController.set_hold`, with exact arm/finger filters, 0.2 s fades, missing-clip fallback and BOX sprint capped at run. H cycles modes in the locomotion test. Seven Godot test suites pass (player 92 checks on the v4 fixture, 94 on installed v7 Kai); actual hold poses also checked on all five v7 characters. Asset audit: 49/49 GLBs import and satisfy the gate; three v7 screen portraits import. Full section 8 inventory, Chapter 1 priorities, review fixes and limitations: [codex_readiness_report.md](production/review/codex_readiness_report.md). No generated assets changed or rendered by this pass. Revised patch cleanup preserves protected UVs/donor pixels, samples each map independently and leaves ambiguous green-only marks for review; its array tests pass, but Blender crashed at startup before the read-only integration probe. Toon/face/outline fixes are headlessly checked, not visually approved. Chapter 1 rooms, gameplay UI, audio and game-ready cutscenes remain missing; pre-v7 props/plants still need toon treatment and functional parts. Transparent decals retain their source materials pending a toon transparency pass.

**27 Oct day (v7 polish):** stray AI-painted flags painted out of every character's colour, normal and roughness textures (no cover layers; self-check: no flag green left anywhere); hold poses `CarryBox_pose` and `HoldRight_pose` added to all five (44 clips; `tools/add_hold_poses.py`, game layers them on the arm bones). Toon look fixed in Godot: the shaders squared the albedo and glTF's default metallic factor blacked out the bodies (shared ramp now in `game/shaders/toon_ramp.gdshaderinc`); FaceAtlas picked the wrong atlas row and lost its texture on a second setup. Gate 49/49; all seven Godot test suites pass. Codex (account 2) is adding the hold layer to the player, reviewing these fixes and writing the readiness audit.

**27 Oct afternoon (v8 characters):** all five characters are now built from the v8 turnaround sheets (arms in one A-pose in every view; side views with the near arm removed), which ended the extra arm Tripo modelled on the v7 backs. Mei's first v8 model carried her left arm twice (forward- and back-swung; the copy was weighted to the spine and stayed behind); Tripo's quad mode repeated it, so her model is the dense generation decimated to 57k in Blender (tools/blender_cleanup.py --rigged). Check any new model from the side and in slices before rigging: a front or back view hides a mirrored arm. Mei's brows stay painted (no_brows): they run into her fringe line. Godot: the player now applies toon materials, FaceAtlas and HairSprings itself; FaceAtlas fits the smooth face lighting to each drawn face (no shading band on the chin); faces ignore sun shadows; the gaze lets go of targets behind the shoulder. The locomotion test (scenes/dev/locomotion_test.tscn) switches characters with 1-5 / Tab. Player test 104 checks pass; gate 49/49.

**Animation fixes (27 Oct, evening), after the user's review of the demo (shrugged shoulders, a hip-forward standing pose, flapping run arms):** tools/retarget_clips.py no longer copies clavicles from the mocap (the library idles shrug 16-29 degrees, the walks drop 12-19): they follow the upper arm like a shoulder blade (rest while hanging, rise only past 60 degrees of lift). Standing idles hang the arms clear of each character's own hips (measured on the mesh), elbows soft and back, palms to the thighs. Standing clips (POSTURE) are tilted to a 2-degree forward spine lean (the idles swayed back 7-18 degrees) and keep 45 % of their knee bend (they crouched 13-26 degrees). Walks and runs keep the wrists nearly straight and get one cyclic smoothing pass on the arms; the player samples gait cycles through cubic rotation curves. Checks: shoulder tops at or below rest in idle, spine lean +0..+2, idle knees 5-12 degrees, no arm pops in stops, turns and pivots (per-frame arm rotation logged in Godot). Second pass (same evening, after the user's next test): Amara, Mei and Rafi walk with Kai's Quick_Walk (their library walks were a posed-hands 'thoughtful' walk, a glitchy cycle and a hip-swaying swagger; tools/build_character_v7.sh); a rest hand roll beyond 40 degrees off palm-down is corrected in every clip (Amara's sculpt holds her hands ~90 degrees round, which turned her palms backward); the player no longer plays the library SprintStop and RunToWalk one-shots (the arms flailed up to 57 degrees a frame): stops and slow-downs blend down through the gaits. Codex review fixes: the hang palm table no longer overwrites the finger-pose PALM (thumbs), the palm twist turns about the forearm itself, the arm smoothing keeps duplicated loop ends equal (tools/test_smooth_cycle.py), and the cubic sampling works on a copy. Palms now face the body at 12-46 degrees on average in walk, run and sprint for all five.

**27 Oct night (v7 anime):** all five characters rebuilt in the anime cel style and installed in Godot (gate 49/49). Pipeline and next steps: [HANDOFF.md](HANDOFF.md) "READ THIS FIRST". Codex is building the toon shaders, face runtime, hair springs, movement system and a readiness audit.

**Character rebuild v4 runtime (26 Oct, Codex):** `game/scripts/face_expression.gd` now mixes expressions and scheduled blinks with the unchanged `LipSync` runtime; `game/scripts/head_accent.gd` adds optional, bounded speech-onset head/neck motion (off by default). `test_face_expression.gd` passes 65 checks, including runtime `GLTFDocument` loading of the scratchpad Kai build (21 blend shapes, 65 bones). `test_lip_sync.gd` passes all 15 existing checks; its generated cue fixtures now use and clean the system temporary directory so it can run in a sandbox. Exact output, sandbox diagnostics and scene wiring: [codex_face_report.md](production/review/codex_face_report.md). These checks do not install or visually approve the five v4 GLBs; their sign-off and installation remain pending in [HANDOFF.md](HANDOFF.md).

**26 Oct:** (historical: the 27 Oct v8 cast replaced these rigs with the 65/68-bone Tripo Mixamo rig and 44 clips) 49 assets in Godot, all verified (gate + visual review); the five characters now have Meshy rigs (24 bones, no finger bones) with 25 clips each (locomotion, idles, conversation, sit, care and repair actions), gate-checked for bones, clips and loops. All 23 cutscene shots done and reviewed ([cutscene_review.md](production/review/cutscene_review.md)). Next: Codex re-review of the six audit re-renders, collision and lightmap import setup for props, the 29 planned assets (environment kit first), audio, `.ogv` conversion.

**Earlier (25 Oct):**

**Done**
- Art bible, prompt log, Chapter 1 manifest, scene index.
- Style lock: cadet key frame v4 and the no-eyes Alo key frame approved.
- Five cast turnarounds approved and split into views.
- **Kai final:** `production/models/final/CH_Kai/CH_Kai.glb` (49,999 tris, 1.74 m, 78-bone skeleton, 4K PBR, skinning verified; historical, replaced by the v8 cast).
- 25 pitch-video props exported from Tripo for reuse (free) into `production/models/reuse/`; the dosimeter is checked and production quality, the rest still need review.
- Pipeline scripts: split_turnaround, make_character, blender_cleanup (+ smoke test), render_preview, pose_test, tripo_api.

**Asset status (25 Oct 2026, 23:40):** 40 assets in Godot, all passing the automated gate; 39 verified (gate + visual review), PR_Dosimeter needs its baked screen replaced, PR_PollinationKit not yet generated (needs ~55 credits). Live numbers: [production/ASSET_REGISTRY.csv](production/ASSET_REGISTRY.csv).
- Characters (5): Kai, Amara, Mei, Rafi, Ferreira, rigged and verified.
- Plants (7): Alo bud, bloom and pods; Tara bloom; cotton; 2034 seedling tray; crop rack.
- New props (10): growth chamber, Mission Table, vault case, seed case, glovebox, Malapert relay, survey beacon, crew seat, hand light (+ pollination kit pending).
- Reused props, vehicles and environment pieces (20).
- Noor's present-day portrait for screens: `production/concept/characters/CH_Noor_portrait_present.png`.
- Audio and cutscene plans ready: 385 voice lines, 12 music cues, 35 sound effects, 23 cutscene shots with prompts.

**Next**
1. Review the four new characters' previews and pose tests.
2. Alo and Tara growth-stage sheets, then 3D (Meshy or Tripo); review the reused plant models first.
3. Clean up the reusable props; replace baked screen text with live UI materials.
4. Environment kit for Aurora (Commons, service rooms, garden, Safe Room, airlock) for Chapter 1.
5. Designed voices for the cast; sound-effect library; CUE-01 to CUE-04.
6. First cutscenes for Chapter 1 (CS-01 to CS-03) from 3D start frames.
7. Animation set for the cadets.
8. Set up Git LFS before the first model commit.

## 11. Delegation between AI tools

- **Claude Code:** planning, design docs, generation pipeline, orchestration.
- **Codex** (model `gpt-6-astra`, reasoning effort high): code review of every script, and the independent visual review of asset contact sheets. `codex exec -s read-only -m gpt-6-astra -c model_reasoning_effort="high" -i <image>... "<prompt>"`. (`gpt-6.1` is not available on the ChatGPT-login account.)
- **Antigravity:** UI and frontend work and browser testing. Not used for visual asset QA: its first review got 5 of 5 FIX calls wrong.

## 12. Known conflicts and open questions

- Older design docs still mention Bangla text and UI ([01_GAME_VISION.md](game-design/01_GAME_VISION.md), [13_UI_UX_DESIGN.md](game-design/13_UI_UX_DESIGN.md) and others) and plant faces ([04_CHARACTER_BIBLE.md:53](game-design/04_CHARACTER_BIBLE.md#L53), [14_ASSET_PRODUCTION_LIST.md:52](game-design/14_ASSET_PRODUCTION_LIST.md#L52), [01_GAME_VISION.md:25](game-design/01_GAME_VISION.md#L25), [docs/GAME_PLAN_FINAL.md:391](docs/GAME_PLAN_FINAL.md#L391)). Section 3 overrides them; updating those docs is pending the user's go-ahead.
- [12_CINEMATIC_DIRECTION.md](game-design/12_CINEMATIC_DIRECTION.md) CIN-04 mentions "unopened buds"; the final canon allows no buds in the annex. CS-05 follows the final canon.
- The old 4-hour scope in 01_GAME_VISION is superseded by the 10–14 hour story edition (720 target minutes); README and GAMEPLAY_DESIGN_FINAL now say so. The numeric puzzle contracts still apply.
- The Tripo API pool shows 2,000 "frozen" credits; only the 1,000 are treated as spendable until the user explains them.
- Ferreira's turnaround reads a little younger than mid-40s; age can be pushed in the face texture.
- CS-01-B (Ferreira speaking with no lip-sync) and CS-02-A (horizon glow, graded in post) are archived realistic shots in [shots.csv](production/cutscenes/shots.csv); the current anime cuts are in [production/cutscenes/v7/](production/cutscenes/v7/).
