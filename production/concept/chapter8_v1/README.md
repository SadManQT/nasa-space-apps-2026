# Chapter 8 (The Lighthouse) assets: 2D sheets for approval (M3-8A)

Board task M3-8A, phase 1 (7 Nov 2026, Sadman/claude, Claude Opus 5.5). **Status: waiting for Sadman's approval.
Nothing is built in 3D yet: no Tripo or Meshy 3D credit has been spent.** Approve, change or decline each numbered
decision below; phase 2 starts from the answers.

**One page to approve from:** [00_Approval_Sheet.png](00_Approval_Sheet.png) stacks the five sheets.

| Sheet | Asset | How it was made |
|---|---|---|
| [M3-8A_EN_MalapertSummit_sheet.png](M3-8A_EN_MalapertSummit_sheet.png) | LOC-12, the 30 x 20 m relay work platform on the Malapert summit | Blender 5.2 Cycles on the real LOLA summit, dated Sun and Earth; procedural pieces |
| [M3-8A_EN_RelayRoad_sheet.png](M3-8A_EN_RelayRoad_sheet.png) | LOC-11, five playable road segments, repeaters R1-R3, the marker-two service pad | Blender 5.2 Cycles at R2 on LOLA 40 m + the 80 m corridor, in the dated dark |
| [M3-8A_EN_NoorRooftop_sheet.png](M3-8A_EN_NoorRooftop_sheet.png) | Noor's rooftop in Dhaka (Earth screen scene, S10 and S12) | Blender 5.2 Cycles, procedural; the approved EN_EarthDesk painted grade |
| [M3-8A_CH_Noor_sheet.png](M3-8A_CH_Noor_sheet.png) | Dr Noor Rahman, present day | Tripo CLI `image` (gemini_3_pro_image_preview) from the installed portrait |
| [M3-8A_CH_Rao_sheet.png](M3-8A_CH_Rao_sheet.png) | Rao, Earth flight controller | Tripo CLI `image` (gemini_3_pro_image_preview) from the installed screen portrait |

Credits: Tripo web plan 810 before and 810 after the six image generations (the image tool did not charge, as on
5-6 Nov); no Meshy, no ElevenLabs, no money. Every generation is in
[production/ai_log_parts/M3-8A.md](../../ai_log_parts/M3-8A.md).

## Sources followed

- **Canon:** STORY_FULL EX-CH08-S01..S12 (word for word where quoted), doc 24 §2.8, the §2.9 CH08 bridge rows and clue 22
  (the relay data panel), §7.5 (the three-place call; Dhaka in the **morning**, 08:15, no Moon in her sky), LOC-11 and
  LOC-12 (game-design/09 via the execution prompts), the character bible (Noor, Rao).
- **Science:** the summit stands on PGDA Site23 5 m LOLA with the authored sub-5 m crater layer and malapert_vista 40 m to
  the horizon, lunar curvature included; Sun and Earth are the JPL Horizons rows in
  `game/assets/environment/terrain/lola/sun_positions.json` (EX-CH08-S10: Sun azimuth 18.1, elevation +2.3; Earth
  358.7, -2.3, clear of the -4.4 deg summit skyline). The road uses the M3-7A route simulator's computed road and three
  pads (`production/tools/route_simulator_data.py`), so the CH07 fabrication-bench model and the CH08 road are the same
  road. EX-CH08-S04's row puts the marker-two pad in the dark (Sun 0.06 deg below the horizon behind a 5 deg skyline).
- **Look:** photoreal environments (5 Nov realism lock) with the ART_BIBLE §3 palette on the hardware (off-white, navy,
  signal orange, role gold on tether lines); the cel-shaded cast (v8 style) for Noor and Rao.

## Canon checks done (by eye on every image, and in the scripts)

- No NASA logos, flags or agency marks on any hardware; the characters wear no badges.
- No Bangla script and no lettering at all: road signs are pictograms, every readout is a live `Screen` slot, the Dhaka
  rooftop and city carry no signs, boards or posters.
- Plants: the rooftop mustard is the installed PL_Tara_Bloom model (four-petal Brassica rapa, no face); the other pots
  are plain leaves. The road slope sign was redrawn once because its first pictogram (two dashes over a triangle) could
  read as a face.
- Moon rules (ART_BIBLE §2): black sky; one hard low Sun; near-black shadows; no fog, haze, wind or dust plumes; no
  stars drawn over sunlit ground; Earth at its true 1.9 deg and dated phase. The Dhaka haze is Earth's air.
- Hands: every hand on both character sheets counted at 3x (five fingers each).

## Decisions for Sadman (approve, change or decline each)

1. **Summit layout and pad level.** The 30 x 20 m pad is cut level 0.3 m under the summit crown and filled outward. A
   pad at the median ground height puts the crown between the crew and Earth (Earth sits only about 2 deg above the
   summit skyline). Relay deck north-west, controller housing at ground level with its service door facing the rover
   pad (east), rover parked heading west so its cabin window looks at the housing (the S06 -> S07 bridge), Earth
   viewpoint on the north edge, the road entering from the south-west. Approve the plan, or change it.
2. **Rebuild the relay procedurally, don't reuse PR_MalapertRelay on the summit.** The installed Tripo relay has its
   dish baked about 30 deg upward, but Earth is 2.3 deg *below* level from a 5 km summit. Its cabinet also cannot open.
   The rebuild keeps its design (navy truss deck, orange rails, white cabinet, dish and mast) with an aimable dish, an
   opening housing, a test point, an isolator and live screens. PR_MalapertRelay stays in the registry for distant or
   older uses. Alternative: keep the Tripo mesh and accept the wrong dish angle.
3. **Where S08 and S09 are played.** Suited at the pedestal beside the housing (dials L and E, the obstruction
   meter, the ALO42 checksum terminal). The rover cabin console mirrors all three over the umbilical for S09's
   acknowledgement and the S10 call, so nobody talks from the open exterior in S10. Alternative: everything after the
   repair in the cabin.
4. **The dated Earth is a thin crescent.** On 9 Apr 2047 the Sun and Earth stand 19.9 deg apart in the summit sky, so
   Earth is 3 % lit: a thin arc on the Sun's side, resting just above the skyline (sheet panels A and D). The game's
   exteriors already draw Earth's phase from the same row (`earth_sky.gd`). **CS-15 (accepted, shipped) shows a nearly
   full Earth high above the ridge.** Choose: (a) keep CS-15 as staged film, or (b) add a board task to repaint Earth in
   CS-15-A and -D as the crescent (a still edit of their start frames plus a re-animation).
5. **Road segments.** Five short playable segments, 700 m in all: A Marker one (140 m, S03), B The dark marker
   (160 m, S03, with the unsupported bypass and its turnback barrier), C Marker-two service pad (120 m, S04 EVA), D
   Marker three (140 m, S04), E Summit approach (140 m, S06). S11 reuses D, C and A in reverse. Rest laybys L1 and
   L2 sit on the compressed cruise. They are placed at the simulator's real pads; the map labels the game's 120 km
   beside the computed 198 km.
6. **Repeaters on high ground with spurs.** The pads stand 1.5-2.5 km off the road on high ground, as the M3-7A
   simulator chose them: down on the road, R1 -> R2 and R2 -> R3 are blocked by ridges. Each segment that serves a pad
   includes its graded spur with guide lights. Alternative: put the pads on the road. That breaks the simulator's
   clear four-hop chain, which CH07-S11 teaches.
7. **Lighting the dark road.** S03 and S04 are dark by the dated rows. Light comes only from the rover's headlights,
   two new **roof work floods** (to be added to VH_Rover as light sockets), amber guide lights every 18 m and suit
   lamps. Distant high ground catches the grazing Sun on the horizon. No stars are drawn when lit ground is in frame.
   Decide also: a faint star field in frames with no lit ground at all (realistic for a dark-adapted camera), yes or no.
8. **New road pieces.** A repeater: 3 m mast on a ballasted tripod in PR_SurveyBeacon's language, with an amber ring
   lamp, two panel antennas along the chain, two adjacent-link lamps, a battery bay with a hinged lid and a removable
   battery module. Also a pictogram-only slope sign, a striped turnback barrier and a layby supply cache.
   PR_SurveyBeacon stays the CH04 survey beacon.
9. **Fetch the 10 m terrain for the road segments.** The 40 m LOLA grid under segment C is cached; the 10 m LDEM_83S
   tiles are not, although M1-87's note assumes they are. Phase 2 (with M1-87) needs about 8-12 tiles of free public NASA
   PGDA data, about 0.5 MB each, from pgda.gsfc.nasa.gov to cut the walkable 10 m patches. Approve the download, or keep
   40 m plus the authored craters.
10. **Noor's rooftop.** Morning for S10 (08:15 Dhaka, Sun 34 deg in the east), as doc 24 §7.5 and the accepted
    CS-15-B have it. This supersedes the registry's "at night". A noon variant serves S12 ("Show me the cotton by the
    window."). It is built like EN_EarthDesk: a 3D room rendered once and shown behind the caller on Aurora's Earth
    screen, with the painted grade (sheet panels: plain, painted, noon, and a mock-up with Noor in front). The
    contents are the stair room with the black tank on its roof, the tin shade on bamboo over her table (radio
    handset, tablet, mug), mustard in flower along the parapet, a bougainvillea, a clothesline, and a 14 m road to the
    east that opens the view. No lettering anywhere.
11. **Noor's turnaround.** 1.55 m and about sixty (she matches the installed present-day portrait and CS-15). Sage-green
    kameez, pale salwar, sage dupatta over both shoulders, reading glasses pushed up, brown sandals. The right-side view
    is the left view mirrored, because two takes drew both side views facing left and her outfit is symmetric. The
    dupatta would be modelled as part of the body (skinned, no cloth simulation). Approve, or ask for changes (height,
    age, clothes).
12. **Rao's turnaround, and 3D scope for both.** Rao is 1.78 m, in a light grey polo, charcoal-navy chinos, a brown
    belt, a steel watch on his left wrist, and the headset with the boom microphone on his left. Proposed scope: both
    get full 3D toon bodies in the v8 pipeline, as the board task asks. Rao sits at the Earth desk inside the
    EN_EarthDesk room (that sheet's decision 5); Noor stands on the rooftop with her radio handset for the S10 call.
    This costs about 150 Tripo credits. Alternative: keep both as the installed 2D portraits (no credits), and
    Noor's rooftop shows her portrait as a cut-out.

## After approval (phase 2)

- **EN_MalapertSummit:** export the summit pieces (relay deck with the aimable dish and local antenna, controller
  housing with door, controller bay and three lamp states, isolator, pedestal with the L, E and checksum screen slots,
  solar mast and battery, tether anchors, perimeter markers, umbilical post, viewpoint rail, cable trays) as GLBs with
  two LODs, `-col` collision and named sockets (door hinge, controller slot, test point, isolator handle, dish and
  antenna axes, tether rings, rover parking). Add a catalogue JSON (pad level, layout, anchors, dated sky) in
  `game/assets/environment/EN_MalapertSummit/`. Run `sync_to_godot.sh`, the gate, a contact sheet in
  `production/review/` and registry rows set to verified. Placing the pad on the LOLA tile in the LOC-12 room is
  M3-8R's job, using `exterior_terrain.json`.
- **EN_RelayRoad:** the same for the repeater (dark and lit states, lid and battery sockets), battery module, guide
  light, slope sign, turnback barrier and supply cache. Add a catalogue with the five segments, the pads, the laybys
  and the spur geometry from `road_data.py` in `game/assets/environment/EN_RelayRoad/`. Add the roof-flood light
  sockets to VH_Rover if decision 7 is approved. The 10 m patches go with M1-87 if decision 9 is approved.
- **EN_NoorRooftop:** final renders of the S10 and S12 backdrops at the Earth-screen size (1536 x 864) with the painted
  grade, in `game/assets/ui/screens/EN_NoorRooftop*.png`, and the Blender source kept here. Binding the caller to it on
  the commons screen means a change in `campaign_crew.gd` / `ui_kit.json`, and that becomes a board task for the
  folder's owner.
- **CH_Noor and CH_Rao** (if decision 12 is approved): the free Tripo `image` second pass per view (the M3-3A upscale
  route), then Tripo multiview (about 60 credits each), the Mixamo rig (about 20-25 each), the cast's 44 clips
  transferred (`transfer_clips.py`, no Meshy), a toon face and hold poses (Noor's radio handset, Rao seated). Then the
  side-view mirrored-arm check, the 65-bone and 44-clip gate, previews and the registry. Check the balance first: the
  default account (810) is shared with M3-4A, and a job moves to the API pool if the web plan runs low.
- Every generation is logged in `production/ai_log_parts/M3-8A.md`, the handbook §8 rows are updated, and the board
  task is marked done with the evidence.

## Files here

- `ch08_common.py`, `summit_kit.py`, `road_kit.py`: the Blender helpers and the procedural pieces.
- `build_summit.py`, `build_road.py`, `build_rooftop.py`, `build_pieces.py`: the Cycles renders. Run each through
  `python3 production/tools/heavy.py blender -b --factory-startup --python <script>`. The renders go to the
  git-ignored `production/models/chapter8/render/`.
- `road_data.py` (system Python, no network): the 40 m window round R2 and the road, pad, segment and layby table.
- `summit_layout.json`: the summit plan, the anchors and the dated sky used by the build and the sheet.
- `compose_ch08.py`: the five sheets and the approval page.
- `characters/`: the four kept takes and `provenance.json` (exact prompts, Tripo task ids, hashes and the balance
  read before and after each generation; the two rejected takes are recorded there and deleted).
