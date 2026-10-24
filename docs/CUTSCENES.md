# Last Light Academy · Cutscenes

**Tool:** ElevenLabs Flows · video model **Seedance 2.5** (`bytedance-seedance-v2.5`): up to 1080p, clips up to 30 s,
up to 10 reference images. Voices with ElevenLabs Text to Speech, music with ElevenLabs Music.

**Status:** shot list ready; nothing generated yet. Story and lines follow [STORY_FINAL.md](STORY_FINAL.md) and the
Chapter 1 script in [GAMEPLAY_DESIGN_FINAL.md §7](GAMEPLAY_DESIGN_FINAL.md#chapter-1--night-one) (dialogue IDs C1-xx).

**Timing and rules:** the competition rules say teams may not start working on the challenge before the hackathon
([competition-rules.md](competition-rules.md), section B). Until the Dhaka Local Lead confirms otherwise in writing,
only the prompts, references and one style test happen before 13 November; the final clips are generated during the
event. Every clip is listed in the project page's **Use of AI** field with its prompt, as the Bangladesh guide requires.

---

## 1. Rules that keep cutscenes and gameplay looking like one game

0. **Playable 3D first.** As GAMEPLAY_DESIGN_FINAL §3 says, pre-rendered footage is only for brief transitions and
   history; it never replaces playable 3D. Footage in judge videos is labelled as cutscene or as real gameplay.
1. **Same references everywhere.** Every clip uses our approved reference sheets and renders of our own 3D models
   (from Tripo/Meshy, rendered in Blender or Godot) as start frames or reference images. No clip is made from text
   alone.
2. **Pre-rendered for the big cinematic moments** (space, the Sun, Earth, Alo close-ups), where AI video shines.
   **In-engine** (real-time, with our actual models) for crew dialogue, so the cadets on screen are exactly the
   ones you play.
3. **No on-screen lip-sync in pre-rendered clips.** The voices in pre-rendered clips are a narrator, radio voices
   (Ferreira, Rao) or a recorded message (N.). This lets one video work in **English and Bangla**: the video carries
   music and sound effects, and the game plays the voice track for the chosen language, with subtitles drawn by the
   game.
4. **One continuous action per clip** (Seedance works best this way). A 20-second scene is 3–4 clips of 4–8 s,
   edited together.
5. **Consistency language** in every image-to-video prompt: *"maintain exact appearance from the reference images,
   consistent design throughout, no deformation or drift"*, plus negatives: *"no text, no logos, no distortion, no
   extra limbs, no flicker"*.

## 2. Priority (the event's real build window is short)

Video 2 needs a working demo by 6:30 PM on 13 Nov, about 11.5 hours after the 7 AM start
([competition-rules.md](competition-rules.md) §A and §B). So cutscenes are tiered, and the game must work without
any of them (a title card and the in-engine camera can stand in):

| Tier | Clips |
|---|---|
| **Must** | C04 Earth-set · C06-B First Light (Bloom) |
| **Should** | C03 Last Light · C08 N.'s message · C06-G Golden Bloom |
| **Could** | C01 2019 history · C02 Aurora Station · C05 alarm sting · C06-L · C07 Earth-rise · screen loops |

## 3. Shot list

### C01 · 2019: the first sprout freezes (≈20 s)

| Shot | Length | Description | Draft prompt |
|:---:|:---:|---|---|
| 1 | 5 s | A small robotic lander on a grey far-side plain, black sky, Sun low | Slow wide dolly-in toward a small robotic lunar lander resting on a flat grey plain of the Moon's far side; black sky, harsh low sunlight, long sharp shadows, fine dust. Stylised animated-film look, soft toy-like shapes, realistic lunar lighting. |
| 2 | 5 s | Inside its sealed canister: a tiny cotton sprout with two leaves | Macro shot inside a small sealed metal canister: a tiny cotton seedling with two pale green leaves, lit by a thin beam of sunlight from a light pipe; the leaves tremble slightly. |
| 3 | 6 s | Night falls: the light fades, frost creeps over the glass, the sprout droops | Time-lapse: the sunbeam fades to darkness, blue frost crystals creep across the canister window, the seedling slowly droops. Cold blue darkness. |
| 4 | 4 s | Black; text and narration | (Edit only: black screen, text "2019 · The first plant to sprout on the Moon did not survive its first lunar night." Corner label: **History · illustration**.) |

**Voice:** narrator. *"In 2019, a cotton seed sprouted on the Moon. Then the long lunar night came, and it did not
survive."* (STORY-04: the pitch-video line "it froze" is softened here.)

### C02 · Aurora Station (≈25 s)

| Shot | Length | Description | Draft prompt |
|:---:|:---:|---|---|
| 1 | 6 s | Over the rim of Shackleton crater at low Sun; the crater floor in total darkness | Aerial drone shot gliding over the sunlit rim of a huge polar crater on the Moon; the Sun skims the horizon, golden rim light, the crater floor in pitch-black shadow, black starry sky. |
| 2 | 7 s | Aurora Station revealed: compact white modules, two tall solar masts, a small glowing chamber outside | (Start frame: our station exterior render.) Slow orbit around the small Moon base; the two tall solar masts turn gently to track the low Sun; warm light glows in the small windows. |
| 3 | 6 s | Push in to Alo's chamber: the bud with a face, swaying | (Start frame: render of Alo's chamber.) Slow push-in toward the small sealed plant chamber; inside, the little mustard bud sways and opens its eyes. |
| 4 | 6 s | Title card | (Edit/motion graphics: "LAST LIGHT ACADEMY" logo over the station.) |

**Voice:** narrator. *"Now, at the Moon's south pole, one tiny mustard flower must survive. Her name is Alo. In Bangla,
Alo means light."*

### C03 · Last Light (≈15 s), end of shift 3

| Shot | Length | Description | Draft prompt |
|:---:|:---:|---|---|
| 1 | 6 s | The Sun's disc slides behind the distant mountains; the golden light shrinks | Static wide shot of jagged lunar mountains on the horizon; the blinding Sun slowly slides down behind the peaks, the golden rim light shrinks to a thin line and disappears; shadows race across the grey plain. |
| 2 | 5 s | The solar masts' panels go dark; their status lights blink off | (Start frame: solar mast render.) The tall solar panels lose their sunlit glint and fall into shadow; small green status lights along the mast blink off one by one. |
| 3 | 4 s | Alo's chamber lamp switches on; Alo looks up at the dark | (Start frame: Alo render.) Inside the small chamber a warm grow lamp flickers on; the little bud looks up at the black sky, worried. |

**Voice:** Kai, off screen (C1-10). *"Last Light. From here, the jar is all we've got."*

### C04 · Earth-set (≈20 s), start of shift 4

| Shot | Length | Description | Draft prompt |
|:---:|:---:|---|---|
| 1 | 8 s | Earth, half lit, slowly sinks below the jagged horizon | Telephoto shot: the half-lit blue Earth slowly sinks behind a jagged lunar horizon until only a thin blue crescent remains, then it is gone. Black sky, stars. |
| 2 | 5 s | The comm screen: Ferreira's feed breaks into static | (In-engine: the radio screen in the hub, Ferreira loop + static shader + "NO SIGNAL".) |
| 3 | 7 s | The station alone in the dark under the stars | Very wide shot: the small Moon base alone on the dark crater rim, a few warm windows glowing, millions of stars, absolute silence. Slow pull-back. |

**Voice:** Ferreira (radio, breaking up). *"Earth-set in ten seconds. From here, you're on your own."*

### C05 · THIS IS NOT A DRILL (≈5 s), start of the storm

| Shot | Length | Description | Draft prompt |
|:---:|:---:|---|---|
| 1 | 5 s | A red alarm light sweeps the Safe Room; the radiation counter needle jumps | (Start frame: Safe Room render.) Red rotating alarm light sweeps across a small space-station shelter room; a radiation counter needle jumps into the red; tiny sparks flicker in the air. Fast, tense. |

**Voice:** Rafi (in-game, live). Text slam "THIS IS NOT A DRILL" added by the game.

### C06 · First Light, four versions (15–20 s each)

All four share shot 1 (generated once):

| Shot | Length | Description | Draft prompt |
|:---:|:---:|---|---|
| 1 | 6 s | A sliver of Sun climbs over the crater rim; light floods across the plain toward the station | A tiny brilliant sliver of the Sun rises over the jagged crater rim; a wave of golden light rolls across the grey plain toward a small Moon base. |

| Version | Shot 2 (8–10 s) | Draft prompt |
|---|---|---|
| **G · Golden Bloom** | Light pours into Alo's chamber; the bud bursts into a full golden cluster; petals float in the light | (Start frame: Alo render.) Golden sunrise light pours into the small plant chamber; the mustard bud opens into a full cluster of bright yellow flowers, petals drift up through the light beams. Joyful, magical. |
| **B · Bloom** | Light pours in; one tiny yellow flower opens | (Start frame: Alo render.) Sunrise light enters the small plant chamber; one tiny yellow flower slowly opens on the little bud. Gentle, hopeful. |
| **L · Alo lost** | Sunrise reveals frost on the glass; the plant drooped; quiet | (Start frame: frosted Alo render.) Soft sunrise light reaches the frosted plant chamber; the small drooped plant does not move; frost on the glass begins to melt like tears. Quiet, sad, still. |
| **S · Mission stopped** | **In-engine, not pre-rendered:** the crew safe in the Safe Room, lights low, the flight-rule panel reads MISSION STOPPED; onboard system line C1-F2 | — (no live Ferreira, no rescue: Earth is down and the flight rules stop the night before anyone is hurt) |

**Voice:** G and B: Mei, off screen (C1-18), *"Alo… you made it."* L: Mei (C1-F1), *"We kept the crew safe, but Alo
didn't make it. Let's find the decision we can change."*, then the old computer shows one locked recording marked
*for the first bloom* (in-engine).

### Order after First Light (GAMEPLAY_DESIGN_FINAL §7)

C06 (G or B) → **C08** N.'s recording (C1-19) → Tara's bud, in-engine (C1-20) → explicit **"Days later"** card →
**C07** Earth-rise epilogue (C1-21) → debrief → Season map. Earth never rises in the bloom scene itself.

### C07 · Earth-rise (≈15 s), Bloom endings only, after a "Days later" card

| Shot | Length | Description | Draft prompt |
|:---:|:---:|---|---|
| 1 | 9 s | Earth slowly rises over the horizon; the station's dish turns to meet it | The blue Earth slowly rises over the jagged lunar horizon; in the foreground, the small base's radio dish turns to point at it. Hopeful, warm. |
| 2 | 6 s | Comm screen: the signal returns, Ferreira smiling | (In-engine: radio screen, Ferreira loop.) |

**Voice:** Ferreira (C1-21). *"You didn't survive the Moon. You ran it."*

### C08 · N.'s message (≈20 s)

| Shot | Length | Description | Draft prompt |
|:---:|:---:|---|---|
| 1 | 8 s | The old computer in the corner flickers on by itself | (Start frame: old computer render.) An old, dusty computer terminal in a dim corner of a space station flickers to life by itself; its screen glows amber; a slow push-in. |
| 2 | 8 s | An audio waveform; text "MESSAGE · RECORDED 12 YEARS AGO · N." | Close-up of the amber screen: a simple audio waveform pulses as a voice plays. (Text added in edit.) |
| 3 | 4 s | Cut to Mei finding Tara's bud indoors (in-engine, C1-20) | (In-engine.) |

**Voice:** N. (recorded-message filter, C1-19). *"If you're hearing this, Alo bloomed. Good. Now Alo needs a friend. — N."*
The voice must not sound like a live call: it is a local recording, twelve years old.

### Screen loops for in-engine scenes

Ferreira and Rao appear on the hub's radio screen. We make short **talking-head loops** (4–6 s each: talking calmly,
smiling, serious, worried) from their approved portraits, plus one per key line if we want lip-sync. The game plays
the loop and the voice line with subtitles.

## 4. Production steps

1. **Approve** this shot list against STORY_FINAL and the C1 script, and get the Local Lead's answer on pre-made assets.
2. **Reference pack:** cadet sheets, Alo sheet, Ferreira/Rao/N. portraits, station exterior, Shackleton style frame.
3. **3D renders:** start frames from our own models (station exterior, solar mast, Alo's chamber, Safe Room, old
   computer).
4. **Test clip:** generate **C03 shot 1** first to check the look and the credit cost (a style test, kept out of the
   submission unless the Local Lead approves pre-made assets).
5. **Generate** (during the event unless approved earlier) each shot at 1080p, 16:9; two takes, pick the best; re-generate only shots that fail.
6. **Edit:** assemble the shots, add music and sound effects, colour-match to the game's palette.
7. **Export:** master `.mp4` (kept in `assets/source/`, used for Videos 2 and 3) and the game version `.ogv` (Ogg
   Theora, **720p, 24 fps**, because Godot decodes it on the CPU) in
   `assets/cutscenes/`. Voices are separate files per language (`vo/en`, `vo/bn`); subtitles come from the game's
   translation files.

## 5. Music cues (ElevenLabs Music)

| Cue | Use | Mood |
|---|---|---|
| `mus_title` | Title, C02 | Hopeful, gentle; Alo's music-box theme (GAME_PLAN_FINAL §10) with a hint of a Bengali folk melody |
| `mus_day` | Shifts 1–2 | Light, curious, bouncy |
| `mus_last_light` | C03, shift 3 | Warm turning to wistful |
| `mus_night` | Shifts 4 and 7 | Quiet, sparse, soft pads, ticking |
| `mus_storm` | C05, shifts 5–6 | Tense pulse, percussion, rising |
| `mus_first_light` | C06-B, C07 | Swelling, emotional |
| `mus_golden` | C06-G | Full, triumphant, the title melody |
| `mus_lost` | C06-L | Solo piano, gentle |
| `mus_debrief` | Debrief | Calm, proud |
| `amb_*` | Room ambiences, Earth-set silence | Fans, hum, static |
