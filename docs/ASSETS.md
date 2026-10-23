# Last Light Academy · Asset Tracker

Everything Chapter 1 needs, who makes it, its budget, and its status. Budgets are in [TECH_ART.md](TECH_ART.md);
the story and rules are in [GAME_DESIGN.md](GAME_DESIGN.md); cutscene shots are in [CUTSCENES.md](CUTSCENES.md).

**Status:** ⬜ to do · 🟨 in progress · 🔍 in review · ✅ done (in the repo, passes the checks in TECH_ART.md §5)

---

## ⚠️ Rules check first

The README says: *"As the Space Apps rules require, no game code was written before the hackathon."* Assets
(models, textures, audio, video, text) are not code, but please confirm with the official Space Apps 2026 rules or
your local organisers that assets made before the event are allowed, and how to declare them. Until then:

- We prepare **assets only**: no gameplay scripts, no simulation code, no shaders.
- The look-dev scene (for checking assets) has **no scripts**.
- Every asset made before the event is listed in this file with its tool and date, and the README will say so.

## How we work together

1. **Spec and prompt.** For each asset, Claude writes the spec (budget, scale, parts) and the generation prompt.
2. **Reference image.** We make the reference sheet (Claude can generate it in ElevenLabs with Nano Banana Pro or
   Seedream, or a team member makes it). The team approves it before any 3D work.
3. **Generate.** A team member runs Tripo or Meshy with the settings in TECH_ART.md §5 and exports `.glb`.
4. **Upload.** Commit the file to `assets/<type>/<asset_id>/` on the working branch (Git LFS handles big files), or
   share it and Claude commits it.
5. **Review.** Claude checks triangle count, materials, texture sizes, scale, orientation, bones and moving parts,
   and reports a short fix list.
6. **Done.** When it passes, the status turns ✅ and the asset gets its "made before the event" entry.

## Schedule (hackathon assumed 14–15 November 2026; please confirm the date)

| Week | Dates | Focus |
|---|---|---|
| **1** | 24–30 Oct | Approve design · style frames · reference sheets · cadets and Alo in 3D · voices chosen |
| **2** | 31 Oct – 6 Nov | Station rooms and modular kit · hero consoles · animations · exterior terrain · UI set |
| **3** | 7–13 Nov | Cutscenes · music and sound effects · voice lines (EN + BN) · final look-dev and performance test |
| **Event** | 14–15 Nov | Code, gameplay, shaders, data processing, assembly |

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
| ENV-07 | Airlock (locked door) | ≤ 40k | Kit | | ⬜ |
| ENV-08 | Station exterior shell (seen from windows and in cutscenes) | ≤ 60k | Tripo / Meshy | | ⬜ |
| ENV-09 | Alo's chamber (LEAF-like sealed plant chamber) | ≤ 15k | Tripo / Meshy | | ⬜ |
| ENV-10 | Solar masts ×2 (NASA VSAT-like) | ≤ 15k each | Tripo / Meshy | | ⬜ |
| ENV-11 | Exterior terrain near the base + horizon ring (from real LOLA data at the event; placeholder before) | ≤ 200k | Blender | | ⬜ |
| ENV-12 | Sky: star field, Sun disc and glare, Earth (NASA Blue Marble texture) | — | NASA imagery + Blender | | ⬜ |

## E. Props and consoles

| ID | Asset | Budget | Moving parts | Owner | Status |
|---|---|---|---|---|:---:|
| PRP-01 | Battery jar (15 drop slots) + sun-drop mesh | 5k + 200 | Lid glow | | ⬜ |
| PRP-02 | Heater console with 3-position dial | 5k | Dial | | ⬜ |
| PRP-03 | Air maker with bubble tank and lever | 6k | Lever | | ⬜ |
| PRP-04 | Grow lamp rig + switch | 4k | Switch, lamp head | | ⬜ |
| PRP-05 | Pump station with valve wheel and gauge | 6k | Wheel, needle | | ⬜ |
| PRP-06 | Water-wall panel (fill level shown by the shader at the event) | 4k | — | | ⬜ |
| PRP-07 | Supply bundles / crates ×6 shapes (STACK puzzle) | 500–1k each | — | | ⬜ |
| PRP-08 | Radiation counter | 2k | Needle | | ⬜ |
| PRP-09 | Radio / comm screen | 3k | Screen surface | | ⬜ |
| PRP-10 | Mission Table (holographic) | 6k | Holo surface | | ⬜ |
| PRP-11 | Bunks ×4 | 3k each | — | | ⬜ |
| PRP-12 | Plant trays (Veggie-style) ×3 | 2k each | — | | ⬜ |
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

| ID | Asset | Length | Owner | Status |
|---|---|:---:|---|:---:|
| CS-C01 | 2019: the first sprout freezes | 20 s | | ⬜ |
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

| Asset ID | Tool(s) | Date | Who |
|---|---|---|---|
| — | — | — | — |
