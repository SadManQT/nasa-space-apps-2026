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
| PR_SeedCase | ✅ PASS | Top view confirms two compartments of vials (15 + 15) |
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

## M3-3A Chapter 3 assets review — 6 November 2026, Sadman/night-claude2 (Claude Opus 5.5)

Inspected: the Cycles previews on [M3-3A_annex_contact.png](M3-3A_annex_contact.png) and [M3-3A_ch03_assets_contact.png](M3-3A_ch03_assets_contact.png) and the Godot captures `production/qa/evidence/M3-3A_*.png` (pieces stage, corridor with the displaced cover hood, open hatch lit by a hand light, cold annex by headlamp, five helmets, both racks and the rack close-up, the petal flat and mounted), against ART_BIBLE.md §2–§3, the 5 Nov photoreal-environment decision, the approved source assets (PR_Helmet, PL_Alo_Bloom, PL_Tara_Bloom, PL_ZeroSeedlingTray) and the canon counts (7 purple + 5 green; planting day has nothing sprouted). No text or logos on any surface, no NASA marks, no plant faces, metre scale, pivots at the base. Defects found and fixed this round: the planting-day rack exported no cassettes in a render run and then kept the bloom models' leaves (now clean procedural cassettes); the service cover was a 4 cm plate pierced by the leaf's wheel and handles in its rest pose (now a 0.30 m hood standing on the deck); every 1 m ceiling tile carried a fixture coplanar with its face, which z-fought into rows of black dashes, and the ribs sat inside the panel (now plain panels with visible ribs plus a separate fixture tile every 3 m); the frost was ±45 % camouflage blotches (now an even crystalline film); the petal's apex was cut square and its veins read as wood grain; a 2.4 cm notch at the corner piece's rib; the grating's hard bar edges.

Second opinion: Codex (`gpt-6-astra`, high), shown the two contact sheets and five captures: 12 PASS, 3 FIX, all three acted on: the dark open-hatch shot did not show the ladder (hand light added), the rack's stem colours were not readable at rack distance (close-up capture added), and the grating shimmered (texture softened; project anti-aliasing filed as M3-100).

| Asset | Verdict | Notes |
|---|---|---|
| EN_ZeroAnnex_FloorHatch_LOD0 | ✅ PASS | 2 x 2 m deck module: round 0.9 m coaming with orange seat ring, N.R. leaf with dogging wheel, two handles, camera port and sliding shutter, blank nameplate slot; the 1.3 x 0.30 m service cover hood hides the whole hatch at rest and sits 1.2 m aside on the deck in the quake pose; leaf open 100 deg clears the opening (Cycles and Godot) |
| EN_ZeroAnnex_FloorHatch_LOD1 | ✅ PASS | Compatibility LOD: same silhouette, cover hood and moving parts, fewer segments, rivets dropped, 512 px textures |
| EN_ZeroAnnex_Ladder_LOD0 | ✅ PASS | two rails 0.5 m apart, rungs every 0.3 m, wall brackets; reaches the corridor deck 3.0 m up, lit in the open-hatch capture |
| EN_ZeroAnnex_Ladder_LOD1 | ✅ PASS | Compatibility LOD: same silhouette, fewer segments |
| EN_ZeroAnnex_Wall_LOD0 | ✅ PASS | olive-grey 2034 panel under an even hoar-frost film (no blotches, no haze), stiffener rib, dark skirting, conduit, rivets |
| EN_ZeroAnnex_Wall_LOD1 | ✅ PASS | Compatibility LOD: flat panel, same colours and frost, rivets dropped |
| EN_ZeroAnnex_Wall_Corner_LOD0 | ✅ PASS | inside corner, ribs and skirting now meet at the corner (the 2.4 cm notch is closed) |
| EN_ZeroAnnex_Wall_Corner_LOD1 | ✅ PASS | Compatibility LOD: same geometry, 512 px textures |
| EN_ZeroAnnex_Floor_LOD0 | ✅ PASS | open steel grating over a dark pit, bars with rounded shoulders; still shimmers without project anti-aliasing (board M3-100) |
| EN_ZeroAnnex_Floor_LOD1 | ✅ PASS | Compatibility LOD: same geometry, 512 px textures |
| EN_ZeroAnnex_Ceiling_LOD0 | ✅ PASS | frosted panel with five visible stiffener ribs hanging below the face, frosted face meets the 2.6 m wall tops; plain (no fixture) |
| EN_ZeroAnnex_Ceiling_LOD1 | ✅ PASS | Compatibility LOD: same geometry, 512 px textures |
| EN_ZeroAnnex_CeilingLamp_LOD0 | ✅ PASS | the same panel with one dead 0.9 m linear luminaire (dark housing, DeadLamp diffuser slot, grey end caps); eight in the 10 x 6 m sample, no z-fighting |
| EN_ZeroAnnex_CeilingLamp_LOD1 | ✅ PASS | Compatibility LOD: same geometry, 512 px textures |
| EN_ZeroAnnex_TrayBench_LOD0 | ✅ PASS | frosted bench top at 0.9 m with the two PL_ZeroSeedlingTray sockets filled in the sample (young unflowered seedlings only), dead grow-lamp bar, blank label slot |
| EN_ZeroAnnex_TrayBench_LOD1 | ✅ PASS | Compatibility LOD: same geometry, 512 px textures |
| EN_ZeroAnnex_ChartArchive_LOD0 | ✅ PASS | drawer cabinet with the sloped growth-chart board (blank Document_Chart), route sheet under the hinged clear SealedCover (opens 110 deg), map pouch, photo frame and 2034 service tag slots; nothing written on any surface |
| EN_ZeroAnnex_ChartArchive_LOD1 | ✅ PASS | Compatibility LOD: same silhouette and parts, fewer segments |
| EN_ZeroAnnex_SupportStation_LOD0 | ✅ PASS | navy warm-side cart, sloped console with blank Screen and Screen_Gauge slots, two radio handsets, tool-tag hook and hand-light bracket sockets, blank status plate |
| EN_ZeroAnnex_SupportStation_LOD1 | ✅ PASS | Compatibility LOD: same silhouette, fewer segments |
| PL_Descendants | ✅ PASS | 21 Oct rack: 7 purple-stem and 5 green-stem plants instanced from the approved Alo and Tara bloom models (four-petal yellow crosses, lobed leaves, no faces), grow lamp, 12 blank label plates, blank dedication card |
| PL_Descendants_Planted | ✅ PASS | 21 May rack: twelve clean procedural cassettes (the bloom models' footprint and rim) with levelled soil and nothing sprouted, labels and dedication card slots |
| PR_Helmet_Roles | ✅ PASS | approved PR_Helmet with a separate gold visor (lowers 78 deg), crown closed under it, role stripe down the back of the shell in each cadet's colour, Bangladesh flag decal on the wearer's left, Aurora patch on the right; no text, no agency marks |
| PR_PressedPetal | ✅ PASS | one dried Brassica rapa petal (obovate, rounded apex, paler claw, veins fanning from the claw) on a blank archival card in a clear sleeve, blank date label slot |
| PR_PressedPetal_Mounted | ✅ PASS | the same sleeve standing in a navy board clip with steel spring clips |
