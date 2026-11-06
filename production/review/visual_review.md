# Visual review

Each asset's concept compared with its finished renders (contact sheets in this folder), against [ART_BIBLE.md](../ART_BIBLE.md). Automated checks are in [asset_verification.md](asset_verification.md). An asset counts as verified only when both pass.

Reviewed 25 Oct 2026 by Claude Code; second opinion by Antigravity (section at the end).

## Verdicts

| Asset | Verdict | Notes |
|---|---|---|
| CH_Kai | ✅ PASS | Matches turnaround; pose test deforms cleanly. 26 Oct: re-rigged with Meshy (24 bones, metres) with 25 clips (19 preset + 6 text-to-motion: Pollinate, Water, Inspect, Type, Repair, plus the in-place Carry_loop preset); every clip rendered (`render_anim.py --action all`) and checked: clean deformation in kneel, bend-over pick-up, seated and run poses, no intersections. No finger bones: hands keep their modelled pose. |
| CH_Amara | ✅ PASS | Braided hair and darker skin as in key frame; clean pose test. 26 Oct: re-rigged with Meshy (24 bones, metres) with 25 clips (19 preset + 6 text-to-motion: Pollinate, Water, Inspect, Type, Repair, plus the in-place Carry_loop preset); every clip rendered (`render_anim.py --action all`) and checked: clean deformation in kneel, bend-over pick-up, seated and run poses, no intersections. No finger bones: hands keep their modelled pose. |
| CH_Mei | ✅ PASS | Bob, pencil and seed pouch; clean pose test. 26 Oct: re-rigged with Meshy (24 bones, metres) with 25 clips (19 preset + 6 text-to-motion: Pollinate, Water, Inspect, Type, Repair, plus the in-place Carry_loop preset); every clip rendered (`render_anim.py --action all`) and checked: clean deformation in kneel, bend-over pick-up, seated and run poses, no intersections. No finger bones: hands keep their modelled pose. |
| CH_Rafi | ✅ PASS | Checklist strap; clean pose test. 26 Oct: re-rigged with Meshy (24 bones, metres) with 25 clips (19 preset + 6 text-to-motion: Pollinate, Water, Inspect, Type, Repair, plus the in-place Carry_loop preset); every clip rendered (`render_anim.py --action all`) and checked: clean deformation in kneel, bend-over pick-up, seated and run poses, no intersections. No finger bones: hands keep their modelled pose. |
| CH_Ferreira | ✅ PASS | Gold tabs, worn suit, holster; reads a little younger than mid-40s (push age in the face texture later). 26 Oct: baked letters on the chest name tag found in a close-up and painted out (blank navy plate, gold border kept); diffed renders show nothing else changed. 26 Oct: re-rigged with Meshy (24 bones, metres) with 25 clips (19 preset + 6 text-to-motion: Pollinate, Water, Inspect, Type, Repair, plus the in-place Carry_loop preset); every clip rendered (`render_anim.py --action all`) and checked: clean deformation in kneel, bend-over pick-up, seated and run poses, no intersections. No finger bones: hands keep their modelled pose. |
| PL_Alo_Bud | ✅ PASS | Purple stem, closed bud cluster, no face |
| PL_Alo_Bloom | ✅ PASS | Purple stem, four-petal flowers; leaves slightly thinner than concept |
| PL_Alo_Pods | ✅ PASS | Dry pods, yellowing leaves |
| PL_Tara_Bloom | ✅ PASS | Green stem, flowers |
| PL_Cotton_Young | ✅ PASS | Palmate leaves, squares, no boll |
| PL_ZeroSeedlingTray | ✅ PASS | Seedlings only, no buds (matches final canon) |
| PL_CropRack | ✅ PASS | Reused |
| PR_GrowthChamber | ✅ PASS | Glove ports, shutter frame, soil tray |
| PR_MissionTable | ✅ PASS | Central display to become a live UI material |
| PR_VaultCase | ✅ PASS | Dusty insulated case, ID window |
| PR_SeedCase | ✅ PASS | Top view confirms two compartments of vials (15 + 15). 6 Nov: rebuilt by M3-7A with exactly one seed per vial (the Tripo vials held many seeds each), see the M3-7A section |
| PR_Glovebox | ✅ PASS | Two pairs of glove ports, side hatch, gauge |
| PR_MalapertRelay | ✅ PASS | Dish, local antenna, controller cabinet, railed platform |
| PR_SurveyBeacon | ✅ PASS | Tripod, housing, dish, orange ring |
| PR_CrewSeat | ✅ PASS | Harness, floor rails |
| PR_HandLight | ✅ PASS | Generated at standard quality (last credits); fine at prop scale |
| PR_ControlConsole | ✅ PASS | Screens to become live UI materials |
| PR_PowerPanel | ✅ PASS | |
| PR_BatteryJar | ✅ PASS | Gold "sun-drops" fit the game's energy visual |
| PR_OxygenUnit | ✅ PASS | |
| PR_WaterValve | ✅ PASS | |
| PR_WaterWallPanel | ✅ PASS | |
| PR_HatchDoor | ✅ PASS | |
| PR_SupplyBundles | ✅ PASS | |
| PR_Recorder2034 | ✅ PASS | |
| PR_CrewBunk | ✅ PASS | |
| PR_Helmet | ✅ PASS | Recolour role stripes per cadet later |
| PR_Dosimeter | ✅ PASS | Fixed 26 Oct: baked graph painted out and flattened; the screen is now its own flat surface with a "Screen" material (surface 1) for the live dosimeter UI. `blank_texture_region.py <glb> 672 440 965 745 --res 1600 --fill <out> --color 10,16,20 --flatten --screen 12` |
| PR_PollinationKit | ✅ PASS | Brushes A (cyan band) and B (green band) in the tray, clear lid, navy latches, orange catch; Codex agrees |
| PR_IceScanner | ✅ PASS | Contact plate, navy grip, orange trigger, lanyard; screen becomes a live UI material |
| PR_ManualGauge | ✅ PASS | Brass gauge on navy bracket, quick-connect; plain ticks, no numbers; needle animated in-engine |
| PR_RepairClamp | ✅ PASS | Hinged clamp, navy seal, orange wing knobs |
| PR_RelayController | ✅ PASS | Crate with module, cable coil and blank note |
| PR_UplinkFeedthrough | ✅ PASS | Scorched feedthrough, two cables, navy junction box |
| PR_SampleHolder | ✅ PASS | Window shows grey regolith, orange tag, carry loop |
| PR_SeedPacket | ✅ PASS | Blank label, sleeve with two seeds (ALO / N. comes as a UI decal) |
| PR_Mug | ✅ PASS | Navy band, orange handle, sipper lid; lid slightly lumpy up close, fine at 11 cm |
| PR_AnnexDrum | ✅ PASS (exterior / annex debris only) | Sits on a pile of regolith, so do not place it on clean interior floors |
| VH_Rover | ✅ PASS | Faces forward; bounding height includes the antenna mast |
| VH_ReliefLander | ✅ PASS | |
| VH_ZeroAscent | ✅ PASS | Archive images only |
| EN_CorridorSegment | ✅ PASS | |
| EN_ExteriorModule | ✅ PASS | |
| EN_SolarMast | ✅ PASS | |

## Removed during review

| Asset | Why |
|---|---|
| PR_BatteryJar_B | Near-duplicate of PR_BatteryJar |
| PR_Helmet_Alt | Duplicate of PR_Helmet, and its visor has a yellow-brown desert baked into the reflection (art bible: grey regolith only) |

Sources of removed assets are archived at `~/nasa-space-apps-2026-archive/tripo-account1/props/`.

## Second opinion (Antigravity, 25 Oct 2026)

Antigravity reviewed all contact sheets independently: 35 PASS, 5 FIX. Each FIX was checked against close-ups and new from-above renders:

| Asset | Antigravity's claim | Checked result |
|---|---|---|
| CH_Mei | Pixie cut; missing pencil and seed pouch | Rejected: close-up shows the same short bob as the concept, the orange pencil behind the right ear and the seed pouch on the hip |
| CH_Ferreira | Youthful cadet head; no gold commander tabs | Partly valid: gold epaulettes, trim and holster are present (rejected); the face does read younger than mid-40s (already noted above; age the face texture later) |
| PR_Helmet | Visor missing in the front render | Rejected: the visor is raised and semi-transparent; the from-above view shows it clearly |
| PR_MissionTable | Flat disc without the central display | Rejected: the from-above view shows the round glass display in the centre |
| PR_SeedCase | Empty shell without vials | Rejected: the from-above view shows both compartments full of vials |

Lesson applied: side-on renders hid open lids and table tops, so every prop preview now includes a high three-quarter view (`top34`), shown in the fourth column of the prop sheets.

## Second opinion (Codex, model gpt-6-astra, reasoning effort high, 25 Oct 2026)

Run on readable strips of at most six assets, with the from-above column included. **41 of 41 PASS** (PR_PollinationKit reviewed separately on 26 Oct), in agreement with the verdicts above. On PR_Dosimeter it reported the screen as "too small to verify"; the close-up in the main review shows a baked graph, so that FIX stands. Codex is now the standing second reviewer (the user prefers it to Gemini/Antigravity).

## Second opinion on the 26 Oct props (Codex, gpt-6-astra, high)

7 of 8 PASS. PR_SeedPacket was called FIX because its front and three-quarter renders are edge-on (the packet is 1.2 cm thick); a 1000 px from-above render shows the blank label and the two seeds in the sleeve, so the FIX is rejected. Review sheets for thin flat props must use the from-above view.


## M1-35 geometry review — 4 November 2026, Tanvir/Codex

All 48 rock LOD renders and the three provisional ground surfaces inspected against ART_BIBLE.md. First build rejected for open fracture caps; rebuilt closed convex hulls and added manifold/volume/area assertions. Four diagnostic contact sheets: M1-35_rock_contact.png, M1-35_rock_LOD1.png, M1-35_rock_LOD2.png and M1-35_regolith_contact.png. Original procedural shapes, not lunar scans. Grey angular forms, no lettering/vegetation/faces/atmosphere. Final review after Tanvir selected M1-33 option A retains the neutral grey rough surfaces for the detailed exterior around the cel-shaded cast. All 60 asset hashes remain unchanged; refreshed native evidence and review are in M1-35.md.

| Asset | Verdict | Notes |
|---|---|---|
| EN_LunarRock_01_Chip_LOD0 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_01_Chip_LOD1 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_01_Chip_LOD2 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_02_Shard_LOD0 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_02_Shard_LOD1 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_02_Shard_LOD2 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_03_Block_LOD0 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_03_Block_LOD1 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_03_Block_LOD2 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_04_Slab_LOD0 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_04_Slab_LOD1 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_04_Slab_LOD2 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_05_Chip_LOD0 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_05_Chip_LOD1 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_05_Chip_LOD2 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_06_Shard_LOD0 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_06_Shard_LOD1 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_06_Shard_LOD2 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_07_Block_LOD0 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_07_Block_LOD1 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_07_Block_LOD2 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_08_Slab_LOD0 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_08_Slab_LOD1 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_08_Slab_LOD2 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_09_Chip_LOD0 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_09_Chip_LOD1 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_09_Chip_LOD2 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_10_Shard_LOD0 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_10_Shard_LOD1 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_10_Shard_LOD2 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_11_Block_LOD0 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_11_Block_LOD1 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_11_Block_LOD2 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_12_Slab_LOD0 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_12_Slab_LOD1 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_12_Slab_LOD2 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_13_Chip_LOD0 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_13_Chip_LOD1 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_13_Chip_LOD2 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_14_Shard_LOD0 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_14_Shard_LOD1 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_14_Shard_LOD2 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_15_Block_LOD0 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_15_Block_LOD1 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_15_Block_LOD2 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_16_Slab_LOD0 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_16_Slab_LOD1 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_LunarRock_16_Slab_LOD2 | PASS geometry and surfaces (option A) | M1-35 geometry and surfaces verified against M1-33 option A |
| EN_Regolith_Fresh | PASS geometry and surfaces (option A) | 4 m tile; surface verified against M1-33 option A |
| EN_Regolith_Compacted | PASS geometry and surfaces (option A) | 4 m tile; surface verified against M1-33 option A |
| EN_Regolith_Disturbed | PASS geometry and surfaces (option A) | 4 m tile; surface verified against M1-33 option A |

## M1-05 habitat kit review — 5 November 2026, Sadman/night-fable (Claude Fable 5.1)

All 26 Cycles previews ([M1-05_habitat_kit_contact.png](M1-05_habitat_kit_contact.png), [M1-05_habitat_kit_lods.png](M1-05_habitat_kit_lods.png)) and the Godot captures (`production/qa/evidence/M1-05_godot_*.png`) inspected against the approved sheets `production/concept/environment_v1/01_HabitatKit_sheet_A_labelled.png` / `_B_labelled.png` and ART_BIBLE.md §3 and §7: palette tokens (suit white, navy, signal orange, water blue), no text or logos on any surface, no faces, metre scale, pivots at the base, LOD1 keeps the silhouette and colours with the relief, rivets and small controls dropped. Surfaces are PBR (quilt, powder-coat paint, brushed steel, anti-slip deck) per the 5 Nov photoreal-environment decision; the toon pass can still restyle them. Second opinion (Codex) not run on the night shift.

| Asset | Verdict | Notes |
|---|---|---|
| EN_Kit_Wall_Straight_LOD0 | ✅ PASS | quilted off-white panel in a light-grey frame, steel handrail at 1.0 m on two brackets, navy skirting with grey cap: matches sheet A piece 1 |
| EN_Kit_Wall_Straight_LOD1 | ✅ PASS | Compatibility LOD: same silhouette and colours, flat quilt, fewer segments, 512 px textures |
| EN_Kit_Wall_Corner_LOD0 | ✅ PASS | two 0.5 m quilted legs at 90 deg with a corner column; inner faces checked from the room side: matches sheet A piece 2 |
| EN_Kit_Wall_Corner_LOD1 | ✅ PASS | Compatibility LOD: same silhouette and colours, flat quilt, fewer segments, 512 px textures |
| EN_Kit_Wall_Window_LOD0 | ✅ PASS | rounded navy pressure-window frame with rivets and a recessed glass pane, quilt above and below, painted surrounds: matches sheet A piece 3 (window scaled to keep whole quilt rows) |
| EN_Kit_Wall_Window_LOD1 | ✅ PASS | Compatibility LOD: same silhouette and colours, flat quilt, fewer segments, 512 px textures |
| EN_Kit_DoorFrame_LOD0 | ✅ PASS | 3 m two-sided pressure frame, arched lip, stiffener ribs, orange grab handle each side, threshold; open state parks the leaf (orange handle, recessed field) inside the wide jamb: matches sheet A piece 4 |
| EN_Kit_DoorFrame_LOD1 | ✅ PASS | Compatibility LOD: same silhouette and colours, flat quilt, fewer segments, 512 px textures |
| EN_Kit_Hatch_LOD0 | ✅ PASS | round leaf with navy seal ring, chrome three-spoke locking wheel, two orange handles, viewport, collar with 24 rivets, hinge knuckles; open state swings into the room: matches sheet A piece 5. Fix round 2: the leaf's far face carries a second locking wheel on the same shaft, two orange handles and the viewport (checked in the open-state preview), so the hatch works from either module |
| EN_Kit_Hatch_LOD1 | ✅ PASS | Compatibility LOD: same silhouette and colours, flat quilt, fewer segments, 512 px textures |
| EN_Kit_Wall_EquipBay_LOD0 | ✅ PASS | recessed navy console with a blank dark screen (material 'Screen', no text), four toggles, two lamps, round gauge, orange handles each side: matches sheet A piece 6 |
| EN_Kit_Wall_EquipBay_LOD1 | ✅ PASS | Compatibility LOD: same silhouette and colours, flat quilt, fewer segments, 512 px textures |
| EN_Kit_FloorTile_LOD0 | ✅ PASS | dark anti-slip deck 4 mm proud of a navy rim, four steel tie-down rings in navy washers: matches sheet B piece 1 |
| EN_Kit_FloorTile_LOD1 | ✅ PASS | Compatibility LOD: same silhouette and colours, flat quilt, fewer segments, 512 px textures |
| EN_Kit_CeilingTile_LOD0 | ✅ PASS | 4 x 4 quilted cells in a grey rim, round vent grille with slats, sensor dome: matches sheet B piece 2 |
| EN_Kit_CeilingTile_LOD1 | ✅ PASS | Compatibility LOD: same silhouette and colours, flat quilt, fewer segments, 512 px textures |
| EN_Kit_PipeRun_LOD0 | ✅ PASS | two water-blue pipes with bolted steel flanges, white duct with a coupling band, two grey bracket feet: matches sheet B piece 3 |
| EN_Kit_PipeRun_LOD1 | ✅ PASS | Compatibility LOD: same silhouette and colours, flat quilt, fewer segments, 512 px textures |
| EN_Kit_CableRun_LOD0 | ✅ PASS | navy tray with end flanges, inspection window over five coloured cables, orange latch clip: matches sheet B piece 4 |
| EN_Kit_CableRun_LOD1 | ✅ PASS | Compatibility LOD: same silhouette and colours, flat quilt, fewer segments, 512 px textures |
| EN_Kit_LightStrip_LOD0 | ✅ PASS | brushed-steel housing with two clips and a warm emissive diffuser: matches sheet B piece 5 |
| EN_Kit_LightStrip_LOD1 | ✅ PASS | Compatibility LOD: same silhouette and colours, flat quilt, fewer segments, 512 px textures |
| EN_Kit_BulkheadRing_LOD0 | ✅ PASS | fix round 2: rebuilt as the deep corridor segment sheet B piece 6 draws (it was a 0.3 m frame that could not form a corridor): 1 m along Z, two flanged grey end frames with an orange outer band and an orange seal lip, quilted liner on seven flats between them, longerons over the liner seams, anti-slip tread with navy kick strips, steel handrails at 1.0 m, 28 bolt heads; chained segments read as one corridor with an orange seal line at each joint (Godot corridor capture) |
| EN_Kit_BulkheadRing_LOD1 | ✅ PASS | Compatibility LOD: same silhouette and colours, flat quilt, fewer segments, 512 px textures |

Fix round, 5 Nov (same reviewer): the kit was rebuilt deterministically with its four texture sets stored once and shared by every GLB (geometry byte-identical to the first build, previews and both sheets re-rendered, verdicts unchanged). The Godot kit-overview captures `M1-05_godot_kit_lod0.png` and `_kit_lod1.png` were blank in the first build (camera aimed before entering the tree) and are re-taken with the camera on the face side and the game LOD forced; LOD0 shows the quilt relief, rivets and controls that LOD1 drops. Room, open-state and corridor captures re-taken with the shared textures: no visible change.

Fix round 2, 5 Nov (Sadman/night-claude3, Claude Opus 5.5): two pieces rebuilt from the same script, the other 22 GLBs, every texture and every material byte-identical (md5 checked). EN_Kit_BulkheadRing is now the 1 m corridor segment of sheet B (above); EN_Kit_Hatch's leaf is two-sided (above). The Godot sample-assembly captures were re-taken because the first ones were blown out (six 2.2-energy omni lights 5 cm under the ceiling, Filmic tone mapping) and their captions ran off the frame: the room is now lit only by a soft-shadowed downlight under each light strip, with screen-space bounce light and AgX tone mapping, so the ceiling takes bounce light as under real recessed strips; the corridor is four chained segments between two door modules instead of two loose rings in a void; the open hatch shows a lit segment and the next door. Inspected: `M1-05_godot_room.png` (far wall, quilt relief, steel handrails, navy skirting, deck rings, no clipping), `_room_open.png` (door leaf parked in the jamb, corridor through the doorway, hatch leaf's room face and the passage beyond), `_corridor.png` (liner, rails, tread, seal lines, 5000 K strip, room through the open door), `_kit_lod0/1.png` (captions now fit). No text or logos on any surface, no faces, metre scale.

## M3-7A Chapter 7 shelter and uplink props, EN_Fabrication — 6 November 2026, Sadman/night-claude2 (Claude Opus 5.5)

Reviewed on the Cycles previews and the review sheets `production/qa/evidence/M3-7A_contact.png`, `_states.png`, `_lods.png`, and in Godot (`M3-7A_godot_*.png`). Independent second opinion: OpenAI Codex CLI (gpt-6-astra, high, read-only), two passes: the first asked for clearer evidence (telemetry and diagnostic close-ups, the low-Sun shadow, a smaller summit label), the second gave all nine PASS. No text, logos or flags on any surface; role colours from ART_BIBLE section 3; no plants in this set. The designs are new procedural props (no credits): Sadman checks them in play.

| Asset | Verdict | Notes |
|---|---|---|
| PR_ShelterDiagram | ✅ PASS | 0.80 x 0.66 m navy board, white enamel 8 x 6 m Safe Room plan (orange hatch, blue water panels, four bundle slots, gold seed latch), five seat rings on the interior side; five markers in the ART_BIBLE role colours parked on the steel strip and snapping to the seats (Godot close-up); status strip is a live slot |
| PR_ShelterDiagram_LOD1 | ✅ PASS | Compatibility LOD: same plan, markers and colours, fewer segments, 512 px kit textures |
| PR_SeedCase | ✅ PASS | rebuild of the approved seed_case_v1 design (white case, navy rim and corner guards, orange draw latch): two foam compartments of 3 x 5 clear vials, exactly one ~2 mm Brassica rapa seed in each (macro render; the suite counts 30 from the geometry), inner seal lids with lamps, hinged lid, side grips, sealed-telemetry window |
| PR_SeedCase_LOD1 | ✅ PASS | Compatibility LOD: 30 simplified vials, same silhouette and colours |
| PR_ValveDiagram | ✅ PASS | enamel mimic: garden reservoir (green band), six water units whose fills show W, pump, supply and return valve symbols with lamps, two-position return selector, live return-time screen |
| PR_ValveDiagram_LOD1 | ✅ PASS | Compatibility LOD: same mimic, fewer segments |
| PR_TelemetryDisplay | ✅ PASS | navy wall unit, two live screens (systems, garden) and the six E A H C R Z lamps between them, keys, speaker, orange grab handles; close-up text readable in Godot |
| PR_TelemetryDisplay_LOD1 | ✅ PASS | Compatibility LOD: same silhouette and colours |
| PR_ArchivePlayer | ✅ PASS | grey rugged player with navy corner guards, speaker grille, live screen, play/pause/stop keys with raised icons, volume knob, archive card, folding handle; no antenna (stored recordings only) |
| PR_ArchivePlayer_LOD1 | ✅ PASS | Compatibility LOD: same silhouette and colours |
| PR_UplinkFeedthrough | ✅ PASS | the approved 27 Oct Tripo mesh unchanged, plus a collision box and an orange lockout tag under the junction box shown once F-EXT is diagnosed; exterior capture under a 4 degree Sun with black sky and grey regolith; the plate's faceting is pre-existing |
| PR_UplinkFeedthrough_LOD1 | ✅ PASS | Compatibility LOD: decimated to a third, bounds kept, 512 px maps |
| PR_NetworkDiagnostic | ✅ PASS | navy cabinet with a mimic of the local network, the feedthrough on the dashed hull line and the Earth dish; three guarded test buttons, three branch lamps, isolation key with lamp, live screen (PASS/FAIL/FAIL readable in Godot), data card |
| PR_NetworkDiagnostic_LOD1 | ✅ PASS | Compatibility LOD: same mimic and controls, fewer segments |
| EN_Fabrication_Bench_LOD0 | ✅ PASS | steel-frame bench with ESD mat, drawers, vise, controller cradle (takes PR_RelayController), spare battery on its cradle, connector tray with three round plugs and one rectangular wrong one, echo test unit, clipboard with a paper sheet, tool board with shadowed tools, shelf, bins and task light |
| EN_Fabrication_Bench_LOD1 | ✅ PASS | Compatibility LOD: same layout, fewer segments |
| EN_Fabrication_RouteSimulator_LOD0 | ✅ PASS | navy table with a relief of the real LOLA corridor (crater detail from the 80 m data, no grid banding after the tangent-frame normal fix), orange computed road, Aurora mast and summit dish markers, three repeater pins, tilted monitor with a live screen |
| EN_Fabrication_RouteSimulator_LOD1 | ✅ PASS | Compatibility LOD: relief at half density with 1024 px maps, road and pins kept |

## M1-07 Alo and Tara seedlings — 6 November 2026, approved by Sadman

Built procedurally from the M3-99 seedling sheet (approved 5 Nov) by `production/concept/plants/build_sprout_glb.py`. Reviewed on `production/qa/evidence/M1-07_sprout_review_contact.png` (seed, cotyledon and true-leaf nodes from four sides, above and with the thirst/cold morphs) and in the garden (`M1-07_garden_*.png`). Sadman approved M1-07 as built in chat on 6 Nov 2026 (about 10:58): "Approve, Space weather".

| Asset | Verdict | Notes |
|---|---|---|
| PL_Alo_Sprout | ✅ PASS | PL_Alo_Bud pot; sown seed in the soil, two heart-shaped seed leaves on a purple hypocotyl, then the first true leaves; Droop and Cup posture morphs; no face, eyes or mouth |
| PL_Tara_Sprout | ✅ PASS | PL_Tara_Bloom pot; same three stages on a green hypocotyl; Droop and Cup posture morphs; no face, eyes or mouth |

## M3-2A Chapter 2 assets (5 Nov 2026, first-pass notes by Sadman/night-fable, Claude Fable 5.1; approved by Sadman 6 Nov 2026)

The sheets are in `production/concept/chapter2_v1/` and the contact sheet is `M3-2A_chapter2_contact.png`. The build is
procedural Blender (no generation), so the renders are the shipped geometry; the automated gate passes for all twelve
files (`asset_verification.md`). Sadman approved the three sheets and the seven README decisions in chat on 6 Nov 2026
(about 10:58): "Approve all as built". The twelve verdicts below are PASS from that approval.

| Asset | Verdict | Notes |
|---|---|---|
| EN_Airlock_SuitLocker_LOD0 | ✅ PASS | open-front locker with rail, helmet shelf, boot tray, retaining bar and orange latch; RoleTab slot tints per cadet in Godot (checked in test_en_airlock.gd); blank plate, no text |
| EN_Airlock_SuitLocker_LOD1 | ✅ PASS | same silhouette, fewer segments, no vent slots or helmet rings |
| EN_Airlock_Bench_LOD0 | ✅ PASS | brushed steel seat (grain repeated four times as often as on the kit's rails, so it reads as fine brushing up close) on navy pedestals; orange boot rail reads at a glance |
| EN_Airlock_Bench_LOD1 | ✅ PASS | same silhouette and colours |
| EN_Airlock_GlovePort_LOD0 | ✅ PASS | kit window frame reused at 1.75 m, two flanged ports with dark sleeves on the far side; quilt above and below matches the kit walls |
| EN_Airlock_GlovePort_LOD1 | ✅ PASS | flat quilt, 10-segment rings |
| EN_Airlock_PassThrough_LOD0 | ✅ PASS | chamber box with navy seal frames on both faces, round viewports in both lids, gauge and orange lever; the far face is finished (two-sided module); lids swing 100 deg as the catalogue says (physics-checked) |
| EN_Airlock_PassThrough_LOD1 | ✅ PASS | same, fewer segments; the flat quilt sits 2 mm proud of the body face (the parked build z-fought there and showed vertical stripes) |
| EN_Airlock_InterlockPanel_LOD0 | ✅ PASS | console in the kit's equipment-bay language: Screen slot, two gauges, three lamps, wheel, grille, lever child; words are live (Label3D) in Godot |
| EN_Airlock_InterlockPanel_LOD1 | ✅ PASS | same, fewer segments |
| PR_PaperBee | ✅ PASS | reads as an origami bee from every view: pleated gold/navy abdomen, pointed head, kite wings folded from a root panel on the thorax, strip legs, antennae rooted inside the head; no face and nothing on the head that reads as an eye (the parked build had a stub there and floating wings); sockets present |
| PR_SeedTray | ✅ PASS | clean 12-cell tray, 0.50 m like PL_ZeroSeedlingTray, navy rim, orange tabs |

Port and rebuild, 6 Nov (Sadman/night-claude2, Claude Opus 5.5): the parked GLBs, previews, sheets, UI icon and
`airlock.json` predated the build scripts' last fixes, so everything was rebuilt from the scripts (a second run is
byte-identical). Changed: PR_PaperBee (wings and antennae as above, 152 triangles), EN_Airlock_PassThrough LOD0/LOD1
(quilt offset), EN_Airlock_Bench (seat grain), `airlock.json` (the six ceiling light strips now sit under the ceiling at
z = 1 and 3 instead of on the near-wall line; interlock `time_compression` note), the plan on the airlock sheet (numbered
anchors that step clear of every label) and the UI icon. The other eight GLBs are byte-identical to the parked build.
Inspected: every Cycles preview, the three sheets, the contact sheet and the Godot captures listed in the board evidence.

## M3-5A Chapter 5 assets review — 6 November 2026, Sadman/night-claude2 (Claude Opus 5.5)

Cycles previews (the sheets `production/concept/ch05_assets/M3-5A_*_v1.png`, all five stacked in [M3-5A_ch05_assets_contact.png](M3-5A_ch05_assets_contact.png)) and the Godot captures (`production/qa/evidence/M3-5A_godot_*.png`, toon materials as in play) inspected against ART_BIBLE §2–§3, doc 24 §2.5, §2.9 (CH05 bridges), §4 clues 17–18 and §5 D9, and the cotton botany in `build_cotton_stages.py`: no eyes, faces or mouths on any plant; no words, numbers, logos or flags on any surface (every record word, timestamp, signature and Ferreira's margin note is live text on a `Page_*` slot); metre scale; pivots at the base. All seven are procedural Blender builds (no generation, no credits), so no 2D approval preceded them; Sadman can still mark any of them FIX from the sheets. Second opinion not run on the night shift.

| Asset | Verdict | Notes |
|---|---|---|
| PL_Cotton_Seed | ✅ PASS | dark ovoid 9.5 mm acid-delinted seed half-buried in a clean sowing dimple in the reused PL_Cotton_Young pot; fix round: the old Tripo soil no longer pokes through the dimple |
| PL_Cotton_Sprout | ✅ PASS | reddish hypocotyl, two kidney-shaped cotyledons, no true leaf yet; Thirst (droop, lean) and Cold (cupped blades) change the silhouette |
| PL_Cotton_Seedling | ✅ PASS | cotyledons plus the first heart-shaped true leaf and a folded second leaf; reads between the sprout and PL_Cotton_Young; same two stress shapes |
| PR_ImpactMonitor | ✅ PASS | navy plinth, deck tilted 18° on a wedge riser (fix round: the deck no longer dips into the plinth), white head, navy bezel, orange grab handles, blank keys and jog wheel; the `Screen` surface shows the authored frames as live UI; fix round: screen 1.5 mm proud of the bezel (it z-fought in Godot) and the import keeps the shared kit textures |
| PR_DocumentSleeve | ✅ PASS | rigid navy A4 case, orange tamper seal, steel latch, blank label window; lid opens about its hinge; fix round: the import keeps the shared kit textures |
| PR_Records2034 | ✅ PASS | four blank 2034 forms told apart by header colour (fault orange, service green, order red with a striped border, manifest navy with a boarding tick per row) under four clear acrylic weights, set down unarranged |
| PR_MarkerTape | ✅ PASS | 19 mm vinyl roll in Kai's orange on a kraft core, and one strip wrapped on a 12 mm cable with a pressed flag |

Port round, 6 Nov (same reviewer): the parked work was ported onto current main and the eight Godot captures were re-taken from it (`production/qa/evidence/M3-5A_godot_*.png`, windowed, toon materials): same content and verdicts as above. The marker-tape shot is re-centred with a shorter stand-in cable, and the capture now retakes a frame that comes back blank.

CH_Ferreira_Duty (screen portrait, no 3D body): Sadman picked take A in chat on 6 Nov 2026 ("Take A"; sheet `production/concept/ch05_assets/M3-5A_ferreira_duty_v1.png`), installed unchanged as `game/assets/ui/portraits/CH_Ferreira_screen.png`. Checked on landing: her v8 face, pixie cut greying at the temples and eyebrow scar; charcoal fleece, one gear-wheel patch, field watch; no flags, badges, lettering or logos; the screens behind her show only a grey Moon disc and plain graphs. In the game: `production/qa/evidence/M1-07_earth_desk_ferreira.png`. Registry: `production/manifest/screen_assets.csv` (2D assets have no GLB gate).
