# Last Light Academy — Art Bible

Version 1.0 · 25 October 2026 · Applies to every model, texture, render and cutscene.
Canon sources: [character bible](../game-design/04_CHARACTER_BIBLE.md), [world/level design](../game-design/09_WORLD_AND_LEVEL_DESIGN.md), [asset list](../game-design/14_ASSET_PRODUCTION_LIST.md), [story](../full-game-story/STORY_FULL.md).

## 1. Look in one sentence

Toon or anime (changed again on 27 Oct 2026; realistic was dropped the same day). The exact style (A anime cel, B stylised toon, C painterly anime) is pending the user's pick from [concept/style_v7/](concept/style_v7/). Characters stay adults with real proportions for their style, distinct silhouettes and friendly, readable faces for players aged 10–15. Hardware and lunar light stay grounded.

**Camera:** third-person follow camera, like Death Stranding ([gameplay spec](../docs/GAMEPLAY_DESIGN_FINAL.md) section 3). The player mostly sees a character from behind, so the back, shoulders, hands, walk and hair shape must identify each person; faces are seen in medium conversation shots, never extreme close-ups.

**Reference blend:** the picked toon/anime style for people + Death Stranding's camera and grounded feel + Artemis/ISS hardware photography.

## 2. Non-negotiable science rules (reject any asset that breaks one)

1. Black sky on the Moon. No atmosphere glow, fog, haze, clouds, wind, rain or blowing dust.
2. Dust only moves ballistically when touched and falls straight down. No billowing.
3. Hard, near-black shadows outside. Sun sits low on the horizon at the south pole; long shadows.
4. Lunar gravity, not zero gravity: people walk and stand; nothing floats indoors.
5. Plants are always inside a pressurised enclosure. Never a flower exposed to vacuum.
6. Radiation is never visible: no glowing particles, lasers or green haze. Only instruments show it.
7. No sound-carrying vacuum effects in cutscenes (no engine roar, explosions or wind outside).
8. Alo/Tara are real field mustard (Brassica rapa): four-petal yellow cross-shaped flowers, lobed leaves, slender pods. Alo's stem is purple, Tara's is green.
9. No NASA logos (meatball or worm). Mission patch is the Aurora/Last Light patch plus the Bangladesh flag patch (user confirmed 25 Oct 2026).
10. Later plants are descendants; the original Alo never reappears alive after Chapter 3.
11. Plants never have eyes, faces or mouths (decided 25 Oct 2026: faces on flowers read as creepy). Every prompt for a plant must say "no eyes, no face".

## 3. Palette

| Token | Hex | Use |
|---|---|---|
| Suit white | `#ECEEF0` | Suit shells, habitat panels |
| Navy | `#1F2A44` | Suit trim, consoles, UI base |
| Signal orange | `#F26B21` | Expedition accent, hazard handles |
| Mustard gold | `#F2C230` | Alo flowers, warm hope beats, title |
| Water blue | `#2E8BC0` | Water wall, coolant lines |
| Regolith grey | `#7A7672` | Lunar surface (never brown or orange) |
| Space black | `#05060A` | Sky |
| Bangladesh green | `#006A4E` | Patch, Noor's rooftop plants |

Role colours (tabs, helmet stripe, UI role icons): **Kai** orange `#F26B21` · **Amara** cyan `#20B8C9` · **Mei** green `#4CAF50` · **Rafi** purple `#8E5CC2` · **Ferreira** steel/gold commander tab `#B8A06A`.

## 4. Lighting

- **Exterior:** one hard key (low Sun, 2–6° elevation), Earthshine as a faint cool fill only when Earth is visible, no ambient sky light.
- **Interior:** warm practical lights (3200–4000 K) in living spaces, neutral 5000 K work light in service rooms, magenta-white grow lamps in the garden, low amber guide lights in the Safe Room.
- **Cutscenes:** motivated lights only. Keep faces readable; a small rim light from a console is allowed.

## 5. Characters

Shared rule (v6, 27 Oct 2026): built on a free realistic human base (MetaHuman recommended) on one skeleton, but every character has their own height, build, face and hair, so no two read alike, even from behind. Ages 19–20 for cadets (young adults, not children). Ferreira is in her 40s. Exact nationalities stay unspecified except Noor (Bangladeshi) and Mei's family link to China. Designs: [concept/cast_v6/](concept/cast_v6/) (portrait = face target, turnaround = build reference). v6 designs await the user's approval.

| Character | Height and build | Face and hair | How they wear the duty coverall, and kit | Reads from behind as | Expression baseline |
|---|---|---|---|---|---|
| Kai (19, power) | 1.74 m, lean and wiry, long arms | Warm medium-brown skin, angular face, thick brows; thick untidy black hair | Unzipped to mid-chest over a grey T-shirt, sleeves pushed to the elbows; worn brown tool belt, scuffed pouch on the right hip, coiled orange cable on the left hip, hand torch at the chest; orange tabs | Messy hair, tool belt, orange cable | Quick lopsided grin; checks switches twice |
| Amara (20, air) | 1.72 m, tall and slender, very upright | Deep dark-brown skin, oval face, long neck; thin box braids in a high bun | Zipped to the collar, spotless, cuffs closed; stylus in the chest pocket, slim tablet holstered on the right thigh; cyan tabs | Tall, high bun, straight back | Calm, precise, dry humour |
| Mei (19, garden) | 1.60 m, small and sturdy | East Asian, light warm skin, round face, freckles; black hair, blunt fringe, low ponytail, pencil behind the right ear | Collar open, sleeves rolled; olive canvas apron with seed-label pockets tied in a bow at the back, plant pouch on the left hip, soil on the knees; green tabs | Shortest, apron bow, ponytail | Warm, attentive, quietly stubborn |
| Rafi (20, safety) | 1.84 m, big and heavy-set, shoulders a little rounded | Light olive-brown skin, broad face, short beard, worried brows; short fade | Charcoal padded safety vest, strap across the chest to a checklist pouch on the left hip, dosimeter badge, radio on the shoulder; purple tabs | Tallest and broadest, vest and strap | Friendly, slightly anxious |
| Ferreira (40s, commander) | 1.68 m, compact and strong | Tanned olive skin, lean face, crow's feet, scar through one eyebrow; short grey-streaked pixie cut | Faded, worn coverall, sleeves pushed up; frayed gear-wheel engineering patch on the left chest, steel field watch, radio pouch; faded gold tabs. Civilian duty layer for Earth screen scenes | Worn, faded fabric, short grey hair | Calm, clipped, warmth held back |
| Rao (adult, Earth control) | Headset, simple Earth desk; screen-only | Friendly, practical |
| Noor (older Bangladeshi botanist) | Modest practical clothes, plant-filled corner, Dhaka rooftop | Gentle, economical |

**Indoor duty coverall (main costume):** the story keeps suits in the vestibule lockers and the cadets work unsuited indoors, so the navy coverall is what players see most. Role-colour tabs on both shoulders, Bangladesh flag patch on the upper LEFT sleeve (real astronaut convention), round Aurora mission patch (yellow mustard flower + crescent Moon on navy) on the upper RIGHT sleeve. No text on clothing.

**EVA suit (exterior, annex entry, rover):** a realistic soft-goods suit in white, navy trim and orange accents, role-colour tabs and helmet stripe, same patch placement. A second outfit on the same skeleton; original design, never a copy of a real agency suit or logo.

## 6. Plants

Field mustard botany first, personality second. **No eyes, face or mouth on any plant.** Alo's personality comes only from movement and posture: leans toward light, gentle sway, leaves droop when thirsty, curls and frosts in cold, perks up after care, flower slowly opens at the bloom beat. These are blend shapes plus a small sway shader, never a face. Growth stages for both plants: seed, sprout, bud, bloom, pollinated, pods, mature-dry; Alo also has an archived pressed-petal state. Cotton: recognisable cotton leaves, healthy young plant, no boll required.

## 7. Technical targets (Godot 4.7, Forward+)

| Class | LOD0 tris | LODs | Textures |
|---|---|---|---|
| Hero character | 40–60k | 3 (60/30/10%) | 4K body + 2K head, PBR |
| Plant (per stage) | 5–15k | 2 | 2K |
| Hero prop (console, vault, rover) | 15–40k | 3 | 2K–4K |
| Small prop | 1–5k | 2 | 1K |
| Modular habitat piece | 2–8k | 2 | 2K trim sheets |

- Units: metres, +Y up, −Z forward in Godot (export GLB from Blender with +Y up).
- Pivot at the base centre for props, at the hinge for doors and valves, at the floor between the feet for characters.
- PBR metal-roughness. Texture names `T_<Asset>_<BaseColor|Normal|ORM|Emissive>`.
- File names `<Prefix>_<Name>_<Variant>.glb`: `CH_` character, `PL_` plant, `PR_` prop, `EN_` environment, `VH_` vehicle, `FX_` effect.
- Collision: simplified `-col` mesh, never the visual mesh.
- No text baked into models. Every label, number and screen is a UI layer (easy to fix or localise later).
- No Bangla script anywhere in the game (user decision, 25 Oct 2026: international audience). English only. The seed packet reads "ALO" and "N." in Latin letters.
- Low-spec fallback: LOD1 must still look right in the Compatibility renderer.

## 8. Cutscenes (Seedance 2.5 via ElevenLabs)

- 16:9, 1080p, 24 fps. Generate from start frames rendered from the final 3D models, so faces, suits and rooms match gameplay.
- One shot per generation (4–15 s); cut together in the composition step.
- Every prompt repeats the science rules from §2 that apply to the shot.
- Speech is added afterwards with ElevenLabs voices and lip-sync, not baked into generated video.
- Earth-side scenes (Noor's rooftop, Rao's desk, Kai's family) are allowed to be fully generated.

## 9. Disclosure log

Every generated asset gets a row in [AI_PROMPT_LOG.md](AI_PROMPT_LOG.md): asset ID, tool and model, exact prompt, input references, date, and what a human changed afterwards. The Bangladesh guide requires this.
