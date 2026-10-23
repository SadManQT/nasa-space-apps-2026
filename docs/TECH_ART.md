# Last Light Academy · 3D Quality and Performance Spec

**Goal:** a professional-looking stylised 3D game that runs **smoothly**, with no stutter, popping or render glitches, on
classroom laptops as well as gaming PCs.

"Smooth" here means measurable targets: a steady frame rate with even frame pacing, no shader-compile hitches, no
visible LOD popping, and fast loading. No game can promise zero lag on every computer, so we set budgets for every
asset and test on the weakest laptop we plan to support, every week.

Related: [Game design](GAME_DESIGN.md) · [Asset tracker](ASSETS.md) · [Cutscenes](CUTSCENES.md)

---

## 1. Targets

| | Minimum (classroom laptop) | Recommended |
|---|---|---|
| **Example hardware** | Intel UHD 620 (8th-gen Core i5), 8 GB RAM | GTX 1650 / RX 6400 / Iris Xe, 8–16 GB RAM |
| **Quality preset** | Low | High |
| **Resolution** | 1080p output, 3D rendered at 720p and upscaled (FSR) | 1080p native |
| **Frame rate** | **30 fps locked**, even pacing (aim for 45+ headroom) | **60 fps locked** |
| **Frame budget** | 33 ms (GPU ≤ 25 ms) | 16.6 ms (CPU ≤ 8 ms, GPU ≤ 12 ms) |
| **VRAM** | ≤ 1 GB | ≤ 2 GB |
| **Load time (SSD)** | ≤ 20 s to the station | ≤ 10 s |

A third **Medium** preset sits between them. Players can change the preset in Settings; the game picks one on first
launch from the GPU name.

## 2. Engine and project settings (Godot 4.7)

| Setting | Choice | Why |
|---|---|---|
| **Renderer** | **Forward+** | Best image quality (SSAO, glow, good shadows, FSR 2) on any Vulkan or Direct3D 12 GPU, including Intel UHD 620. |
| **Fallback** | Compatibility (OpenGL) on computers without Vulkan/D3D12 | Keeps very old laptops playable at reduced quality. We test it once a week; it is a safety net, not the main look. |
| **Physics** | Jolt Physics, 60 ticks per second, **physics interpolation on** | Interpolation makes movement smooth on 75/120/144 Hz screens and when the frame rate dips. |
| **V-Sync** | On (adaptive where supported), with a frame-rate cap per preset | Even frame pacing and no tearing. |
| **Anti-aliasing** | High: MSAA 4× + SMAA · Low: FSR 2 (it includes anti-aliasing) | Clean edges on stylised shapes without TAA smearing. |
| **Shader stutter** | Godot's ubershader and pipeline precompilation, plus a warm-up during the loading screen (every material is drawn once off-screen) | No hitch the first time frost, sparks or a new room appear. |
| **Color** | Linear workflow, AgX tonemapper, one shared `WorldEnvironment` per area | Consistent colour between rooms and cutscene renders. |

## 3. Lighting: the key to "professional and fast"

The Moon is a gift for rendering: one hard light (the Sun), a black sky, no fog and no clouds. We use it.

| Area | Technique |
|---|---|
| **Station interior** | **Baked lighting** (LightmapGI) for walls, floors and static props: soft shadows and bounce light at almost no runtime cost. One ReflectionProbe per room. |
| **Gameplay light changes** | A few dynamic lights on top of the bake: heater glow (orange), lamp (green-gold), alarm (red), frost (blue tint via material). At most **6 dynamic lights visible**, and only **2 casting shadows**. |
| **Exterior** | One DirectionalLight3D for the Sun (very low on the horizon, as at the pole: long, dramatic shadows), 2–4 shadow cascades by preset. Earthshine as a faint blue fill. |
| **Day to night** | The time-lapse animates the Sun's direction and energy plus the emissive strength of the solar masts; the interior bake stays valid because the windows are small. |
| **Not used** | SDFGI, VoxelGI and volumetric fog (expensive, and lightmaps look better for this style). |

## 4. Asset budgets

Every asset must meet its budget before it is marked done in [ASSETS.md](ASSETS.md).

| Asset type | Triangles (LOD0) | Materials | Textures | Notes |
|---|---|---|---|---|
| **Cadet** | 20k–30k | 1–2 | 2048² BaseColor, Normal, ORM | Humanoid skeleton (Mixamo-compatible); helmet as a separate mesh |
| **Alo** | 8k–12k | 1 | 2048² | Blend shapes for moods; bloom stages as blend shapes or swap meshes |
| **Tara, small plants** | 2k–5k | shared | 1024² atlas | |
| **Hero console** (heater, air maker, pumps, jar) | 3k–8k | 1–2 | 1024² | Moving parts as separate nodes (dial, lever, wheel) |
| **Small prop** | 300–3k | shared | trim sheet / atlas | |
| **Room (walls + props)** | ≤ 80k | ≤ 12 | trim sheets 2048² | Modular kit, snapped to a 1 m grid |
| **Exterior terrain** | ≤ 200k total, with LODs | 2–3 | 2048² tiling + detail | From LOLA heightmap; horizon ring mesh from the real profile |
| **Whole visible frame** | High ≤ 1.5M · Low ≤ 600k | | | |
| **Draw calls** | High ≤ 1,000 · Low ≤ 500 | | | |
| **Unique materials per scene** | ≤ 60 | | | Fewer materials means fewer shaders to compile |

**Textures:** PNG sources in the repo; Godot imports them as VRAM-compressed with mipmaps. ORM = ambient occlusion,
roughness and metallic packed into one texture. No 4K textures in the game.

**LOD and culling:** Godot generates mesh LODs on import (keep it on). Rooms use occlusion culling (OccluderInstance3D)
so only the room you are in and its doorway neighbours are drawn. Exterior props use visibility ranges with fade, so
nothing pops.

## 5. The Tripo / Meshy → Godot pipeline

AI-generated models look great in a viewer but often arrive with problems that cause lag or render glitches: hundreds
of thousands of triangles, messy UVs, lighting baked into the colour texture, wrong scale, or flipped normals. Every
model goes through the same steps:

### Step 1: Reference image (one per asset)

- Make a clean **reference sheet** first: front / side / back view, even flat lighting, **no shadows**, plain grey
  background, the exact role colours from §7.
- The same reference sheets are used for the cutscenes, so the game and the cutscenes show the same characters.

### Step 2: Generate in Tripo or Meshy

| Setting | Value |
|---|---|
| Input | Image-to-3D from the reference sheet (multi-view if available) |
| Textures | PBR on (BaseColor, Normal, Roughness, Metallic) |
| Topology | Quad remesh for characters; triangles are fine for static props |
| Target triangles | From the budget table in §4 (ask for slightly fewer, never more) |
| Rigging | Characters: auto-rig to a humanoid skeleton (Tripo auto-rig, or Mixamo) |
| Export | **.glb** (binary glTF) |

### Step 3: Check (and clean up if needed)

Props that pass the checks can go straight into Godot through the Tripo/Meshy plugins. **Characters and hero
consoles always get a check in Blender:**

- Scale: **1 unit = 1 metre**. Cadets are about **1.45 m** tall; Alo's chamber is about 0.5 m.
- Orientation: facing **−Z** in Godot (+Y forward in Blender), origin at the feet / base.
- Transforms applied, normals pointing outwards, no loose or hidden geometry.
- Triangle count and material count within budget.
- Albedo has no baked shadows or highlights (re-generate or paint them out if it does).
- Moving parts (dials, levers, valve wheels, doors) are separate, named objects with their pivot at the hinge.

### Step 4: Import into Godot

- Characters: retarget to Godot's humanoid skeleton profile at import, so all four cadets share one animation set.
- Animations: Mixamo (FBX, "without skin") → retargeted → saved as Godot animation libraries.
- Materials: extracted to `.tres` files and shared where possible.

### Step 5: Look-dev check

Each new asset is dropped into the **look-dev scene** (a lighting test scene with no gameplay) and viewed on the
Low and High presets, with the frame-time monitor open. See the rules note in [ASSETS.md](ASSETS.md).

## 6. Animation and VFX

| Area | Rule |
|---|---|
| **Character animation** | Shared set: idle, walk, jog, interact (button), turn valve, carry crate, cheer, worry, shiver with blanket, talk gesture, point. AnimationTree blend space for locomotion. |
| **Alo** | Blend shapes: neutral, shiver, droop (thirsty), hide (scared), sleepy, bloom stages 1–3, golden. Small idle sway. |
| **Talking (in-engine)** | Simple jaw/mouth shapes driven by voice volume, with subtitles. |
| **Particles** | GPU particles with fixed counts, pre-warmed at load: sun-drops, bubbles, sparks, petals, dust. Max ~5k particles on screen (Low: ~1.5k). |
| **Frost, water wall, ghost preview** | Shader effects made at the hackathon. Only their textures (noise, frost pattern, gradients) are prepared as assets. |

## 7. Art direction (one look for game, UI and cutscenes)

- **Style:** stylised, soft and toy-like, like a modern animated film, but with real NASA hardware shapes.
- **Shapes:** rounded, chunky, readable from a projector at the back of a classroom.
- **Palette:**

| Use | Colour |
|---|---|
| Kai / power | Orange `#FF8A3D` |
| Amara / air | Cyan `#3BC8E7` |
| Mei / garden | Green `#5CC46A` |
| Rafi / Safe Room | Purple `#9B6BF2` |
| Alo / sun-drops | Mustard yellow `#FFD84D` |
| Suits | White `#F4F5F7`, navy `#1D2A4D`, orange trim `#F26B1D` |
| Regolith | Warm grey `#8C8A85` to `#4A4846` |
| Sky | Black, with a faint star field |

- **Rooms** carry their cadet's colour in lights and trim, so players always know where they are.
- **Icons and words together,** never colour alone (accessibility).
- **Font:** Baloo Da 2 (Latin and Bangla, SIL Open Font License).

## 8. Performance test checklist (every week)

- [ ] Walk the full station on the minimum laptop, Low preset: frame time stays under 33 ms, with no spikes over 50 ms.
- [ ] First appearance of every effect (frost, sparks, petals, alarm): no hitch.
- [ ] Switch cadets 20 times quickly: no hitch.
- [ ] Run all 7 shifts: memory stays flat (no leak).
- [ ] Recommended PC, High preset: 60 fps locked.
- [ ] Compatibility fallback starts and is playable.
- [ ] Cutscene playback: no audio drift, no dropped frames.

## 9. Repository layout and naming

```
assets/
  concept/        reference sheets, style frames (PNG)
  characters/     chr_kai/, chr_amara/, chr_mei/, chr_rafi/, chr_alo/, chr_tara/
  environment/    env_room_power/, env_hub/, env_exterior/ ...
  props/          prp_battery_jar/, prp_valve_wheel/ ...
  animations/     anm_*.fbx (Mixamo)
  vfx/            textures for effects (noise, frost, gradients)
  ui/             icons, cards, badges, logo, map
  audio/          music/, sfx/, vo/en/, vo/bn/
  cutscenes/      cs_c01_*.ogv (+ master .mp4 in source/)
  source/         .blend files, high-res masters, raw generations (Git LFS)
docs/
```

**Names:** lowercase with underscores, prefix by type: `chr_`, `env_`, `prp_`, `anm_`, `vfx_`, `ui_`, `mus_`, `sfx_`,
`vo_<lang>_<speaker>_<id>`, `cs_`. Example: `vo_bn_kai_s1_03.ogg`.

**Formats:** models `.glb`, textures `.png`, music `.ogg`, short sound effects `.wav`, cutscenes `.ogv` (Ogg Theora,
the video format Godot plays without plug-ins). All binary files are stored with **Git LFS** (see `.gitattributes`).
