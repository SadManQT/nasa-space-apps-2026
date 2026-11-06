# Chapter 2 (Be the Bee) assets: 2D sheets for approval (M3-2A)

Board task M3-2A. **Status: approved and verified. Sadman, in chat on 6 Nov 2026 (about 10:58): "Approve all as built":
the three sheets and the seven decisions below. Built, gate-passed and installed in the game (first pass 5 Nov; on 6 Nov
the parked work was ported onto main and everything was rebuilt from the scripts, because the parked GLBs, previews and
sheets predated the scripts' last fixes); the twelve visual-review verdicts are PASS and the registry rows `verified`. No Tripo, Meshy or ElevenLabs credit was spent: both assets' planned build
method was Blender, so everything here is procedural geometry rendered with Blender 5.2 Cycles (like the M1-05 kit and
the M3-99 sheets). What you approve is what ships; a change means a re-run of the build script, not a new generation.**

| Sheet | What it shows |
|---|---|
| [M3-2A_EN_Airlock_sheet.png](M3-2A_EN_Airlock_sheet.png) | the 8 x 4 m double-interlock vestibule (three Cycles views and a measured plan) and its five new pieces: suit locker, bench, glove-port module, sealed carrier pass-through, interlock panel |
| [M3-2A_PR_PaperBee_sheet.png](M3-2A_PR_PaperBee_sheet.png) | Rafi's origami bee: three-quarter, front, side, back, top and the transparent UI icon |
| [M3-2A_PR_SeedTray_sheet.png](M3-2A_PR_SeedTray_sheet.png) | Kai's clean 12-cell seed tray (the CH02 S06 → S07 bridge object) |
| [../../review/M3-2A_chapter2_contact.png](../../review/M3-2A_chapter2_contact.png) | every piece LOD0 beside LOD1, the props, the room views |
| `../../qa/evidence/M3-2A_godot_*.png` | the same assets inside Godot (vestibule, pass-through, the panel in all three states, the chamber, the props) |

## Design followed

- **Canon:** LOC-05 in `game-design/09_WORLD_AND_LEVEL_DESIGN.md` (8 x 4 m double-door vestibule; suit lockers, bench,
  sealed carrier pass-through and glove-port access to Alo; independent pressure interlock; connected to LOC-01, LOC-03,
  LOC-06; words SEALED / EQUALISING / SAFE TO OPEN; pump only while cycling). The paper bee and the clean seed tray come
  from STORY_FULL EX-CH02-S02 ("Rafi folds a paper bee and puts it beside the protocol"), S07 ("Kai puts a clean seed
  tray beside the care strip"; "Its folded wing brushes the horticulture recorder and exposes a familiar equipment
  number": the number is on the recorder, so the bee carries no text) and the doc 24 §2.9 bridge rows for CH02.
- **Look:** photoreal environment on the approved kit's materials (5 Nov realism lock), ART_BIBLE §3 palette: off-white
  quilt, navy consoles and skirting, signal-orange handles and latches, steel rails, the five role colours on the locker
  tabs (Kai orange, Amara cyan, Mei green, Rafi purple, Ferreira gold). The bee is mustard-gold duo paper with the navy
  reverse showing at the bands and white wings.
- **Engineering truth:** a real double interlock: the suit-up vestibule and a separate 3 m chamber between two pressure
  hatches, only one open at a time, each panel describing the hatch beside it; the garden is reached by samples (the
  pass-through with two interlocked lids, the glove ports into Alo's sealed chamber), never by people, so the greenhouse
  stays isolated from suit dust. The equalise time (12 s) is a gameplay value in `airlock.json` and openly compressed: a real chamber takes minutes,
  so the room shows a labelled time card for the rest (LOC-05 exit behaviour).

## Canon checks done

English only, no Bangla script; no text baked into any surface (the panel words are a live `Screen` slot and a
`Label3D`; the locker name plates are blank); no logos, flags or NASA marks; no plants in this set, so the no-face rule
does not arise; the room is pressurised, and the Moon rules of ART_BIBLE §2 apply behind the outer hatch (the exterior
is not part of this asset). The bee has no face or eyes.

## Decisions (all approved as built, 6 Nov 2026)

1. **Vestibule layout:** inner door to the commons on the west wall, garden interfaces (glove ports and pass-through) on
   the north wall with no walking door into the garden, partition with the inner hatch at x = 5, outer hatch east. The
   greybox contract (`room_contract.gd` LOC-05) still says 10 x 8 m; canon says 8 x 4 m and this asset follows canon.
2. **Suit lockers:** five (four cadets plus Ferreira's for after 12 Dec), 0.6 m wide, open-front with a retaining bar;
   role-colour tab and a blank name plate. Say if you want doors instead of the open bay.
3. **Pass-through:** 0.50 x 0.44 m chamber at bench height with side-hinged lids and a round viewport each; the
   `LampSafe` lamp reads "sealed" while both lids are shut.
4. **Interlock panel:** the three lamps plus the live words; the lever and wheel are decorative-interactive (the room
   owner animates them on a cycle).
5. **Paper bee:** gold duo paper with navy bands; wings white. The alternative is all-gold with navy stripes drawn on.
6. **Seed tray:** 4 x 3 cells, 0.50 m over the tabs, navy rim, orange tabs. It is sized to carry PL_Descendants (CH03).
7. **Bench seat:** brushed stainless (the kit's steel set, its grain repeated four times as often so the brushing reads at
   a real scale up close), chosen because a bare metal seat wipes clean of suit dust. The alternative is a matte grey
   powder-coated seat like the kit's frames.

## After approval

- Done 6 Nov 2026: the five pieces (two LODs each) and the two props are `verified` in the registry
  (`production/review/visual_review.md` verdicts, then `python3 production/tools/build_registry.py`).
- M1-06 wires `en_airlock.gd` into the LOC-05 room scene; the P-03 mission places the carrier on the pass-through's
  `carrier_socket`.
