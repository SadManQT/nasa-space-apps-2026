# Last Light Academy · Asset Tracker

Preparation tracker for Chapter 1 assets: who prepares each one, its budget, and its status. Budgets are in
[TECH_ART.md](TECH_ART.md); the story is [STORY_FINAL.md](STORY_FINAL.md); the rules and numbers are the P-02
contract in [GAMEPLAY_DESIGN_FINAL.md §6](GAMEPLAY_DESIGN_FINAL.md#6-chapter-1-numerical-contract); cutscene shots are in
[CUTSCENES.md](CUTSCENES.md). The team's full list is [game-design/14_ASSET_PRODUCTION_LIST.md](../game-design/14_ASSET_PRODUCTION_LIST.md).

**Status:** ⬜ to do · 📝 prompt/spec ready (Phase 0) · 🟨 generating · 🔍 in review · ✅ done (in the repo, passes the
checks in TECH_ART.md §5)

---

## ⚠️ Rules first: what may be made before 13 November

The team's rules research ([competition-rules.md](competition-rules.md), section B) found two official lines:

- Global FAQ: *"Teams are not allowed to begin working on the challenges prior to the hackathon."*
- Bangladesh guide: Video 1 is "concept only"; the team's reading is **keep everything before 13 Nov at concept level**.

Making game-ready models, voice lines and cutscenes now could be read as starting the project early. So the plan has
two phases, and one question for the Dhaka Local Lead (Mohammad Mahdee-uz Zaman, contact in competition-rules.md §G):
*"May we prepare art and audio assets before 13 November if we declare them on the project page?"* Ask in writing and
save the answer in this repository.

| Phase | When | What is allowed |
|---|---|---|
| **0 · Concept and preparation** | Now → 12 Nov | Concept art and reference sheets, written specs and generation prompts, voice casting tests, one style test clip, the paper playtest, downloading raw NASA data, rehearsing the Tripo/Meshy → Godot pipeline on throwaway test objects that are **not** used in the game |
| **1 · Production** | 13–14 Nov (Dhaka event) | Generating the final models, animations, voice lines, music, sound and cutscenes from the Phase 0 prompts, plus all code, shaders and data processing |
| **1 early** | Only with the Local Lead's written yes | Phase 1 asset items may move into Phase 0, each logged in the declaration table at the end of this file |

Phase 0 is what makes Phase 1 fast: with approved references and ready prompts, Tripo/Meshy produce a model in minutes
and Seedance a clip in a few minutes, so the core set can be generated in the first hours of the event.

## How we work together

1. **Spec and prompt.** For each asset, Claude writes the spec (budget, scale, parts) and the generation prompt.
2. **Reference image.** We make the reference sheet (Claude can generate it in ElevenLabs with Nano Banana Pro or
   Seedream, or a team member makes it). The team approves it before any 3D work.
3. **Generate (Phase 1).** On 13 Nov (or earlier only with the Local Lead's written yes), a team member runs Tripo or
   Meshy with the settings in TECH_ART.md §5 and exports `.glb`.
4. **Upload.** Commit the file to `assets/<type>/<asset_id>/` on the working branch (Git LFS handles big files), or
   share it and Claude commits it.
5. **Review.** Claude checks triangle count, materials, texture sizes, scale, orientation, bones and moving parts,
   and reports a short fix list.
6. **Done.** When it passes, the status turns ✅. Anything made before 13 Nov gets an entry in the declaration log,
   and every AI tool and prompt goes into the project page's **Use of AI** field.

## Schedule (Dhaka event 13–14 November 2026; global window 14–15 November)

| Week | Dates | Phase 0 focus (concept and preparation) |
|---|---|---|
| **1** | 24–30 Oct | Ask the Local Lead · style frames · reference sheets for the cadets, Alo and the station · voice casting tests |
| **2** | 31 Oct – 6 Nov | Specs and prompts for every model, prop and cutscene · Tripo/Meshy → Godot rehearsal on throwaway objects · paper playtest |
| **3** | 7–12 Nov | One Seedance style test · music and sound briefs · final prompt pack · download raw NASA data · team roles for the event |
| **Event** | 13–14 Nov | Generate assets from the prompt pack (first ~8 hours), then code, shaders, data processing and assembly |

---

## A. Concept and references

| ID | Asset | Tool | Owner | Status |
|---|---|---|---|:---:|
| REF-01 | Style frame: Garden interior (Alo's window, Tara, lamp) | Image model | | ⬜ |
| REF-02 | Style frame: exterior, Shackleton rim at Last Light | Image model | | ⬜ |
| REF-03 | Kai reference sheet (front / side / back, flat light) | Image model | | ⬜ |
| REF-04 | Amara reference sheet | Image model | | ⬜ |
| REF-05 | Mei reference sheet | Image model | | ⬜ |
| REF-06 | Rafi reference sheet (with and without the oversized helmet) | Image model | | ⬜ |
| REF-07 | Alo mood sheet: neutral, shiver + scarf, thirsty, scared, sleepy, bloom 1–3, golden, wilted | Image model | | ⬜ |
| REF-08 | Ferreira, Rao and N. (silhouette only) portraits | Image model | | ⬜ |
| REF-09 | Station exterior concept (modules, masts, Alo's chamber, airlock) | Image model | | ⬜ |
| REF-10 | UI style sheet (icons, cards, colours, font) | Image model + design | | ⬜ |

## B. Characters (3D)

| ID | Asset | Budget | Tool | Owner | Status |
|---|---|---|---|---|:---:|
| CHR-01 | Kai (rigged) | 20–30k tris, 2K textures | Tripo / Meshy | | ⬜ |
| CHR-02 | Amara (rigged) | 20–30k | Tripo / Meshy | | ⬜ |
| CHR-03 | Mei (rigged) | 20–30k | Tripo / Meshy | | ⬜ |
| CHR-04 | Rafi (rigged) | 20–30k | Tripo / Meshy | | ⬜ |
| CHR-05 | Helmets ×4 (Rafi's oversized), separate meshes | 3k each | Tripo / Meshy | | ⬜ |
| CHR-06 | Alo + mood blend shapes / bloom stages | 8–12k | Tripo / Meshy + Blender | | ⬜ |
| CHR-07 | Tara (indoor mustard plant) | 3–5k | Tripo / Meshy | | ⬜ |
| CHR-08 | Alo's tiny scarf, cadet blankets | 1–2k each | Tripo / Meshy | | ⬜ |

> If the cadet models from the pitch video still exist, upload them first. Re-using them saves a week and keeps the
> video and the game consistent.

## C. Animations

| ID | Asset | Source | Owner | Status |
|---|---|---|---|:---:|
| ANM-01 | Locomotion: idle, walk, jog, turn | Mixamo | | ⬜ |
| ANM-02 | Interact: press button, pull lever, turn valve wheel | Mixamo | | ⬜ |
| ANM-03 | Carry and place crate (STACK) | Mixamo | | ⬜ |
| ANM-04 | Emotions: cheer, worry, shiver with blanket, relief, sad | Mixamo | | ⬜ |
| ANM-05 | Talk gestures ×3, point, nod, shake head | Mixamo | | ⬜ |
| ANM-06 | Alo idle sway and mood transitions | Blender | | ⬜ |

## D. Environment

| ID | Asset | Budget | Tool | Owner | Status |
|---|---|---|---|---|:---:|
| ENV-01 | Modular kit: walls, floors, ceilings, doors, windows, pipes, trim sheet | ≤ 80k per room | Tripo / Meshy + Blender | | ⬜ |
| ENV-02 | Mission Table hub | ≤ 80k | Kit + props | | ⬜ |
| ENV-03 | Power room (orange) | ≤ 80k | Kit + props | | ⬜ |
| ENV-04 | Air room (cyan) | ≤ 80k | Kit + props | | ⬜ |
| ENV-05 | Garden (green) with the big window | ≤ 80k | Kit + props | | ⬜ |
| ENV-06 | Safe Room (purple) with bunks and water-wall tanks | ≤ 80k | Kit + props | | ⬜ |
| ENV-07 | Airlock: two doors, suit check, cycle controls (used for the Chapter 1 chamber inspection) | ≤ 40k | Kit | | ⬜ |
| ENV-08 | Station exterior shell (seen from windows and in cutscenes) | ≤ 60k | Tripo / Meshy | | ⬜ |
| ENV-09 | Alo's chamber (LEAF-like sealed plant chamber) | ≤ 15k | Tripo / Meshy | | ⬜ |
| ENV-10 | Solar masts ×2 (NASA VSAT-like) | ≤ 15k each | Tripo / Meshy | | ⬜ |
| ENV-11 | Exterior terrain near the base + horizon ring (from real LOLA data at the event; placeholder before) | ≤ 200k | Blender | | ⬜ |
| ENV-12 | Sky: star field, Sun disc and glare, Earth (NASA Blue Marble texture) | — | NASA imagery + Blender | | ⬜ |

## E. Props and consoles

| ID | Asset | Budget | Moving parts | Owner | Status |
|---|---|---|---|---|:---:|
| PRP-01 | Battery jar (20 drop slots, P-02 cap) + sun-drop mesh | 5k + 200 | Lid glow | | ⬜ |
| PRP-02 | Heater console with 3-position dial | 5k | Dial | | ⬜ |
| PRP-03 | Air maker with bubble tank and lever | 6k | Lever | | ⬜ |
| PRP-04 | Grow lamp rig + switch | 4k | Switch, lamp head | | ⬜ |
| PRP-05 | Pump station with valve wheel and gauge | 6k | Wheel, needle | | ⬜ |
| PRP-06 | Water-wall panel (fill level shown by the shader at the event) | 4k | — | | ⬜ |
| PRP-07 | Supply bundles ×4 (STACK puzzle, P-02: four bundles fill the bunk slots) | 500–1k each | — | | ⬜ |
| PRP-08 | Radiation counter | 2k | Needle | | ⬜ |
| PRP-09 | Radio / comm screen | 3k | Screen surface | | ⬜ |
| PRP-10 | Mission Table (holographic) | 6k | Holo surface | | ⬜ |
| PRP-11 | Bunks ×4 | 3k each | — | | ⬜ |
| PRP-12 | Edible-crop grow rack (food layer C) + plant trays ×3 | 4k + 2k each | Rack lights | | ⬜ |
| PRP-13 | Seed packet (আলো, N.) | 300 | — | | ⬜ |
| PRP-14 | Old computer terminal (N.'s message) | 3k | Screen surface | | ⬜ |
| PRP-15 | Small clutter set: tablets, mugs, tools, cables, labels | 300–1k each | — | | ⬜ |

## F. VFX textures (effects themselves are made at the event)

| ID | Asset | Owner | Status |
|---|---|---|:---:|
| VFX-01 | Frost pattern (tiling, with a mask) | | ⬜ |
| VFX-02 | Spark and particle sprites | | ⬜ |
| VFX-03 | Bubble sprite, petal sprite | | ⬜ |
| VFX-04 | Noise and gradient textures (water wall, hologram, static) | | ⬜ |
| VFX-05 | Sun glare / lens flare sprites | | ⬜ |

## G. UI and 2D

| ID | Asset | Owner | Status |
|---|---|---|:---:|
| UI-01 | Logo (English and Bangla) | | ⬜ |
| UI-02 | Title screen and loading screen art | | ⬜ |
| UI-03 | Icon set: sun-drop, air, water, heat, frost, thirst, growth, dose, lock, star | | ⬜ |
| UI-04 | Role cards ×4 (screen + printable for Class Mode) | | ⬜ |
| UI-05 | Secret envelopes ×4 (screen + printable) | | ⬜ |
| UI-06 | Stars, badges ×4, ending cards ×4 | | ⬜ |
| UI-07 | Season map: 8 chapter tiles (2–8 locked) | | ⬜ |
| UI-08 | Mission patch template (printable, with team name) | | ⬜ |
| UI-09 | Debrief "it was all real" cards (LROC, DONKI, CRaTER, Curiosity) layouts | | ⬜ |
| UI-10 | Input prompt glyphs (keyboard + gamepad; CC0 set) | | ⬜ |

## H. Audio

| ID | Asset | Tool | Owner | Status |
|---|---|---|---|:---:|
| AUD-01 | Voices chosen: Kai, Amara, Mei, Rafi, Ferreira, Rao, N., narrator (re-use the pitch-video voices if possible) | ElevenLabs | | ⬜ |
| AUD-02 | Voice lines, English (from the final script) | ElevenLabs TTS | | ⬜ |
| AUD-03 | Voice lines, Bangla | ElevenLabs TTS + native-speaker check | | ⬜ |
| AUD-04 | Music cues ×9 + ambiences (see CUTSCENES.md §4) | ElevenLabs Music | | ⬜ |
| AUD-05 | Sound effects: clink, spill, dial, lever, valve, bubbles, frost, alarm, sparks, static, door, footsteps, UI clicks, bloom pop (~40) | ElevenLabs SFX | | ⬜ |
| AUD-06 | Alo's voice: chimes, sighs, shiver, happy trill (no words) | ElevenLabs SFX | | ⬜ |

## I. Cutscenes

Tiers (Must / Should / Could) are in [CUTSCENES.md §2](CUTSCENES.md#2-priority-the-events-real-build-window-is-short).

| ID | Asset | Length | Owner | Status |
|---|---|:---:|---|:---:|
| CS-C01 | 2019: the first sprout does not survive the night | 20 s | | ⬜ |
| CS-C02 | Aurora Station / title | 25 s | | ⬜ |
| CS-C03 | Last Light | 15 s | | ⬜ |
| CS-C04 | Earth-set | 20 s | | ⬜ |
| CS-C05 | THIS IS NOT A DRILL | 5 s | | ⬜ |
| CS-C06 | First Light ×4 (G, B, L, S) | 15–20 s each | | ⬜ |
| CS-C07 | Earth-rise | 15 s | | ⬜ |
| CS-C08 | N.'s message | 20 s | | ⬜ |
| CS-LOOPS | Ferreira and Rao screen loops | 4–6 s each | | ⬜ |

## J. Text and data

| ID | Asset | Owner | Status |
|---|---|---|:---:|
| TXT-01 | Full Chapter 1 script (every line, per shift and per ending) | | ⬜ |
| TXT-02 | Bangla translation of the script and UI (native-speaker review) | | ⬜ |
| TXT-03 | Class Mode printables text (role cards, envelopes, teacher guide) | | ⬜ |
| DAT-01 | Raw NASA data downloaded (LROC illumination, LOLA DEM, DONKI Sept 2017, CRaTER, MSL RAD); processing happens at the event | | ⬜ |

---

## Made before the event (declaration log)

The Bangladesh guide asks for every AI tool, **the prompts and the reasoning**, and where the team's own creative work
went (competition-rules.md §E). Claude's specs and prompts count as AI use too.

| Asset ID | Tool(s) | Prompt (or link to it) | Why AI was used | Team's own work | Date | Who | Licence / terms checked |
|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — |
