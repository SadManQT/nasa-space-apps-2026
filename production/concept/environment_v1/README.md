# Habitat kit and Chapter 1 room concept sheets — M1-03 (for approval, M1-04)

Made 5 November 2026 on the night shift (Claude Fable 5.1, Tripo CLI `image` with `gemini_3_pro_image_preview`).
**Nothing is generated in 3D before Sadman approves these sheets** (standing rule; board task M1-04).
Full prompts, task ids and file hashes: [provenance.json](provenance.json). Generation log: `production/AI_PROMPT_LOG.md` (2026-11-05, M1-03 rows).

## Art direction followed

The board task text (written before 5 Nov) asks for the kit "in the approved anime cel style". The later, binding
handbook §3 decision of **5 Nov 2026 (Sadman)** says *ultra-realistic = the environment, not the cast*: photoreal
lunar interiors and exteriors, cel-shaded anime cast. These sheets follow §3: every environment is rendered
photoreal in the look of ISS and Artemis hardware photography, with the Art Bible §3 palette (off-white quilted
panels, navy consoles and trim, signal-orange handles, mustard-gold accents, water-blue coolant lines, grey regolith).
Where cadets appear they are meant as cel-shaded figures composited into the photoreal set (the runtime cast is the
installed v8 GLBs; the figures in the frames are placeholders for scale and lighting only).

For comparison, the first Commons and Garden takes came out fully illustrated (anime line art). They are kept as
`*_alt_anime.png` so Sadman can confirm the photoreal direction or pick the illustrated look instead.

## Files

| File | What it shows | Status |
|---|---|---|
| `01_HabitatKit_sheet_A.png` (+ `_labelled`) | Walls and openings: straight wall 1 m x 2.6 m with handrail, inside corner, window wall, 1.2 m x 2.1 m door frame with sliding pressure door, round pressure hatch ~1.2 m with locking wheel, wall equipment bay (blank screen = live UI surface) | candidate |
| `01_HabitatKit_sheet_B.png` (+ `_labelled`) | Floor tile 1 m, ceiling tile 1 m with vent, pipe run (two coolant pipes + air duct), cable tray, light strip, corridor bulkhead ring 2.6 m | candidate |
| `02_Commons_mood.png` | LOC-01 Aurora commons (22 x 12 m): round Mission Table with map screen and recorder dock, **four** unnamed mugs, Earth screen on standby (no words), blank charter plaque and dedication board, lockers west, galley east, window into the garden; the four cadets at the table (Kai orange, Amara cyan, Mei green, Rafi purple tabs); warm 3500 K practicals | candidate |
| `02_Commons_mood_alt_anime.png` | Same brief, illustrated take (five mugs, "STANDBY" word on the screen: both would be fixed if this look is chosen) | alternate |
| `03_ServiceRooms_mood.png` | LOC-02 power (west) and atmosphere (east) rooms, glass partition, protected trunk; battery "jar" column with the gold full band, power panel, hand light in its marked holder; oxygen tank, benchtop electrolyser, manual taps, colour-banded spur valve; neutral 5000 K work light; no cable maze | candidate |
| `04_Garden_mood.png` | LOC-03 garden (12 x 8 m): indoor Tara bay (one green-stem seedling) under magenta-white lamps; south viewing window with Alo's **sealed** external chamber bolted outside (glass front, shutter raised, purple-stem seedling inside); four glove ports; quarantine glovebox, care bench, seed-archive cabinet; black sky, grey regolith, hard shadows outside | candidate |
| `04_Garden_mood_alt_anime.png` | Same brief, illustrated take with Mei at the bench (two seedlings in the Tara bay) | alternate |
| `05_SafeRoom_mood.png` | LOC-04 Safe Room (8 x 6 m): five harnessed seats (4 + 1), perimeter water panels with level gauges, indexed crate rails with shielding crates, central seed-case latch box, roll-call board with five blank markers, archive speaker, round hatch, low amber guide lights, one telemetry panel | candidate |
| `06_Exterior_mood.png` | LOC-06 mast courtyard: MLI-wrapped modules on legs with airlock hatch and stair, external plant chamber shutter on a module wall, lattice solar masts, 120 m regolith apron with bootprints and orange route markers, rim handrail; black sky, no stars over the sunlit ground, no Earth (below the horizon on 25 Apr 2046), Sun a few degrees up, long hard shadows, no haze or dust | candidate |

Raw sheets stay unlabelled so pieces can be cropped for image-to-3D; the `_labelled` copies carry the piece names and sizes for review (`python3 production/tools/concept_label_kit_sheets.py production/concept/environment_v1`; the contact sheet comes from `production/tools/concept_review_sheet.py <dir> <out.png>`).

## Canon checks done on every frame

English only, no Bangla script; no readable text or logos (one garbled sign on the garden cabinet was blanked by
hand; small stickers on the service-room taps are unreadable and would not exist on the models, since no text is
baked into models); no NASA marks or flags; plants are real young *Brassica rapa* with no eyes, faces or mouths and
always inside a sealed pressurised enclosure; black sky, no haze, fog, wind or airborne dust; hard low-Sun shadows;
lunar gravity; radiation never shown; nothing floats.

## Known deviations to decide on

1. **Exterior shows three lattice masts; canon is twin masts.** The 3D scene will use two `EN_SolarMast` instances; the frame is a lighting and material reference. Say if a re-take with two masts is wanted (~20 Tripo credits).
2. The Sun in the exterior frame has a soft lens halo. It is lens glare, not atmosphere; the in-game sky stays black.
3. Commons: the cadets came out semi-3D rather than flat cel; treat them as placeholders. One extra mug was painted out (four remain, per Chapter 1).
4. Safe Room: the seed case is shown open on the floor at the latch position; in play it is a latched two-compartment case.
5. Kit sheets are 1376 x 768 px (the Tripo image service's 16:9 size). Good enough to approve the designs; for Tripo multiview or image-to-3D, M1-05 should crop a piece and, where a crop is too small, generate a single-piece view of the approved design (logged as usual).

## Approval

Write "approved" or the changes wanted next to each file name (or in the M1-04 board task). The decision is then
recorded in `PRODUCTION_HANDBOOK.md` §3 and M1-05 (3D kit) can start.

## Credits

Tripo web account `default`: the balance read 1,325 before and after all eleven image generations (ten for this
task plus one accidental `--dry-run`, which the CLI does not treat as a dry run). Expected cost per the handbook was
about 20 per image; no charge was observed, so the measured cost is recorded as 0 pending the next balance check.
