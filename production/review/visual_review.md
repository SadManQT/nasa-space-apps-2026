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

## M3-3A Chapter 3 assets review — 6 November 2026, Sadman/night-claude2 (Claude Opus 5.5)

Inspected: the Cycles previews on [M3-3A_annex_contact.png](M3-3A_annex_contact.png) and [M3-3A_ch03_assets_contact.png](M3-3A_ch03_assets_contact.png) and the Godot captures `production/qa/evidence/M3-3A_*.png` (pieces stage, corridor with the displaced cover hood, open hatch lit by a hand light, cold annex by headlamp, five helmets, both racks and the rack close-up, the petal flat and mounted), against ART_BIBLE.md §2–§3, the 5 Nov photoreal-environment decision, the approved source assets (PR_Helmet, PL_Alo_Bloom, PL_Tara_Bloom, PL_ZeroSeedlingTray) and the canon counts (7 purple + 5 green; planting day has nothing sprouted). No text or logos on any surface, no NASA marks, no plant faces, metre scale, pivots at the base. Defects found and fixed this round: the planting-day rack exported no cassettes in a render run and then kept the bloom models' leaves (now clean procedural cassettes); the service cover was a 4 cm plate pierced by the leaf's wheel and handles in its rest pose (now a 0.30 m hood standing on the deck); every 1 m ceiling tile carried a fixture coplanar with its face, which z-fought into rows of black dashes, and the ribs sat inside the panel (now plain panels with visible ribs plus a separate fixture tile every 3 m); the frost was ±45 % camouflage blotches (now an even crystalline film); the petal's apex was cut square and its veins read as wood grain; a 2.4 cm notch at the corner piece's rib; the grating's hard bar edges.

Second opinion: Codex (`gpt-6-astra`, high), shown the two contact sheets and five captures: 12 PASS, 3 FIX, all three acted on: the dark open-hatch shot did not show the ladder (hand light added), the rack's stem colours were not readable at rack distance (close-up capture added), and the grating shimmered (texture softened; project anti-aliasing filed as M3-102).

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
| EN_ZeroAnnex_Floor_LOD0 | ✅ PASS | open steel grating over a dark pit, bars with rounded shoulders; still shimmers without project anti-aliasing (board M3-102) |
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

## M3-3A CH_Cadet_EVA fitted EVA suits — 7 November 2026, Sadman/claude (Claude Opus 5.5)

Inspected: Blender orthographic sheets (front, left, back, right, top) and horizontal slices of every model take (the mirrored-arm test: torso plus two arms in every band from hip to shoulder), pose sheets (idle, walk, run, sit, kneel, type, wave, carry), the hand-to-body clearance of every standing and gait clip, and Godot close-ups in the game look (toon materials, drawn face layers) from both sides and the back, plus the windowed captures `production/qa/evidence/M3-3A_eva_*.png` and [M3-3A_eva_contact.png](M3-3A_eva_contact.png). Against the five sheets Sadman approved on 6 Nov (production/concept/turnarounds_eva_v1), ART_BIBLE §3 role colours and the 25 Oct patch lock. No text, no logos, no NASA marks, no Bangla script; hands are five-fingered gloves with clean wrists; no extra limbs in any slice of the used takes. Rejected on review (logged in production/ai_log_parts/M3-3A.md): Kai take 1 (sheet sides swapped: it faced backwards), six Mei takes (ponytail behind her ear, doubled or split), the first Amara and Ferreira models (white shoulder domes and stray marks on the arms from the arm-free side views) and a Ferreira take built from arm-keeping side views (extra arm).

| Asset | Verdict | Notes |
|---|---|---|
| CH_Kai_EVA | ✅ PASS | orange role tabs and shoulder trim, lean build, his face and untidy hair; flag LEFT sleeve, Aurora RIGHT sleeve and RIGHT chest (the sheet's wrong-side chest badge removed). Known minor: faint pale marks remain on the pack's round cover (Tripo relief under the repaint) |
| CH_Amara_EVA | ✅ PASS | cyan tabs, braids in the low coil at the nape (decision 2), her face; patches as locked. Known minor: a speckled edge where the shoulder trim meets the repainted sleeve |
| CH_Mei_EVA | ✅ PASS | green tabs, blunt fringe, one centred low ponytail on three bones (68 in all) that tucks inside the helmet; freckles; patches as locked, right-chest Aurora decal added (decision 4) |
| CH_Rafi_EVA | ✅ PASS | purple tabs, heavy-set build, beard and fade; right-chest Aurora decal added (decision 4). Known minor: a faint outline of Tripo's painted placeholder below the right-sleeve patch |
| CH_Ferreira_EVA | ✅ PASS | gold tabs, faded and worn suit, gear-wheel patch on the left chest (decision 3), dark brown pixie cut with grey; patches as locked |

Every suit carries its wearer's 44 clips (copied from the installed coverall character; the walk, run and idle poses match), stands 1.62–1.82 m on the wearer's joints, and wears PR_Helmet_Roles at the measured scale (Kai 1.17, Amara 1.28, Mei 1.35, Rafi 1.29, Ferreira 1.16), seated on the neck ring and carried by the Head bone, so the face stays inside the shell in every clip (a chest-bone mount let the clips' head pitch push the faces out: fixed before capture). No independent second opinion this round (Codex not run); Sadman's eye on the captures is the remaining check.

## M3-8A Chapter 8 pieces — 7 November 2026, Sadman/claude (Claude Opus 5.5), approved by Sadman ("Approve all")

Reviewed by eye against the approved sheets in production/concept/chapter8_v1/ from the Cycles stills of the exported GLBs and the Godot captures ([M3-8A_chapter8_contact.png](M3-8A_chapter8_contact.png); production/qa/evidence/M3-8A_godot_*.png). No Codex second opinion was requested for this set (the brief asked for my own review). Canon checks on every piece: no words or numbers baked into any surface (all readouts are named slots), no logos or agency marks, hard-surface hardware only (no plants), lunar exterior pieces with no glow or haze baked in. Science checks in game/tools/test_chapter8_assets.gd: the dish boresight is within 0.3 deg of azimuth 358.7 / elevation -2.3 and the local antenna within 0.3 deg of R3 (216.7 / -4.8).

| Asset | Verdict | Notes |
|---|---|---|
| EN_MalapertSummit_RelayDeck_LOD0 | ✅ PASS | matches the approved sheet: navy truss deck, orange rails, ladder gap on the south side, white RF box; the 2.0 m dish now faces local north and dips 2.3 deg (the sheet's first renders had it facing south, a sign error fixed before export and re-rendered); local antenna aims down-road at R3; four moving nodes |
| EN_MalapertSummit_RelayDeck_LOD1 | ✅ PASS | same silhouette, colours and slots at about 45 % of the triangles; no collision |
| EN_MalapertSummit_ControllerHousing_LOD0 | ✅ PASS | white housing on a navy plinth, door on its north hinge with orange latches and brace handle, controller on rails, orange test-point plate, three dark status lamps; reads as serviceable hardware; no lettering |
| EN_MalapertSummit_ControllerHousing_LOD1 | ✅ PASS | same silhouette, colours and slots at about 45 % of the triangles; no collision |
| EN_MalapertSummit_PowerIsolator_LOD0 | ✅ PASS | post-mounted white box, orange rotary handle (live position in the file; isolated = 90 deg), lock-out tag socket; cables lie on the ground |
| EN_MalapertSummit_PowerIsolator_LOD1 | ✅ PASS | same silhouette, colours and slots at about 45 % of the triangles; no collision |
| EN_MalapertSummit_ControlPedestal_LOD0 | ✅ PASS | console faces the operator (+X) after the sheet fix; three screen slots and two orange dials read clearly; screens are blank until the live UI fills them |
| EN_MalapertSummit_ControlPedestal_LOD1 | ✅ PASS | same silhouette, colours and slots at about 45 % of the triangles; no collision |
| EN_MalapertSummit_SolarMast_LOD0 | ✅ PASS | vertical cell wing with a navy frame on a steel pole, battery cabinet at the foot; stands on its base after the stray fin was removed |
| EN_MalapertSummit_SolarMast_LOD1 | ✅ PASS | same silhouette, colours and slots at about 45 % of the triangles; no collision |
| EN_MalapertSummit_TetherAnchor_LOD0 | ✅ PASS | orange stake, steel plate and ring; reads at a glance |
| EN_MalapertSummit_TetherAnchor_LOD1 | ✅ PASS | same silhouette, colours and slots at about 45 % of the triangles; no collision |
| EN_MalapertSummit_PerimeterMarker_LOD0 | ✅ PASS | white post with an orange reflective cap |
| EN_MalapertSummit_PerimeterMarker_LOD1 | ✅ PASS | same silhouette, colours and slots at about 45 % of the triangles; no collision |
| EN_MalapertSummit_UmbilicalPost_LOD0 | ✅ PASS | white post, navy head, orange socket at the rover's side |
| EN_MalapertSummit_UmbilicalPost_LOD1 | ✅ PASS | same silhouette, colours and slots at about 45 % of the triangles; no collision |
| EN_MalapertSummit_ViewpointRail_LOD0 | ✅ PASS | low orange rail and navy standing plate |
| EN_MalapertSummit_ViewpointRail_LOD1 | ✅ PASS | same silhouette, colours and slots at about 45 % of the triangles; no collision |
| EN_MalapertSummit_CableTray_LOD0 | ✅ PASS | flat navy tray with a steel lid; tiles in 2 m steps |
| EN_MalapertSummit_CableTray_LOD1 | ✅ PASS | same silhouette, colours and slots at about 45 % of the triangles; no collision |
| EN_RelayRoad_Repeater_LOD0 | ✅ PASS | PR_SurveyBeacon language at 3 m: ballasted tripod, white head with navy trim, amber ring beacon, two panel antennas, two link lamps, battery bay with a hinged lid; dark and lit states driven by slots |
| EN_RelayRoad_Repeater_LOD1 | ✅ PASS | same silhouette, colours and slots at about 45 % of the triangles; no collision |
| EN_RelayRoad_BatteryModule_LOD0 | ✅ PASS | navy cell block, white cap, orange handle; sits in the bay socket |
| EN_RelayRoad_BatteryModule_LOD1 | ✅ PASS | same silhouette, colours and slots at about 45 % of the triangles; no collision |
| EN_RelayRoad_GuideLight_LOD0 | ✅ PASS | short white post with the amber lamp slot |
| EN_RelayRoad_GuideLight_LOD1 | ✅ PASS | same silhouette, colours and slots at about 45 % of the triangles; no collision |
| EN_RelayRoad_SlopeSign_LOD0 | ✅ PASS | navy diamond with a white rim and an orange vehicle-on-slope pictogram; no words; the first pictogram (dashes over a triangle) was redrawn because it could read as a face |
| EN_RelayRoad_SlopeSign_LOD1 | ✅ PASS | same silhouette, colours and slots at about 45 % of the triangles; no collision |
| EN_RelayRoad_TurnbackBarrier_LOD0 | ✅ PASS | orange and white banded bollards and bar; reflective caps |
| EN_RelayRoad_TurnbackBarrier_LOD1 | ✅ PASS | same silhouette, colours and slots at about 45 % of the triangles; no collision |
| EN_RelayRoad_SupplyCache_LOD0 | ✅ PASS | navy rack with two white crates and orange latches |
| EN_RelayRoad_SupplyCache_LOD1 | ✅ PASS | same silhouette, colours and slots at about 45 % of the triangles; no collision |

## M3-4A Chapter 4 environments review — 7 November 2026, Sadman/claude (Claude Opus 5.5); approved by Sadman 7 Nov 2026 ("Approve all 12")

Inspected: every published GLB as a studio render, LOD0 beside LOD1, on [M3-4A_ch04_contact.png](M3-4A_ch04_contact.png); the approved Cycles views; the Godot captures `production/qa/evidence/M3-4A_godot_bay.png`, `_exterior`, `_ready`, `_dock`, `_porch`, `_coldtrap_pieces` and `_vault_set` (`M3-4A_capture.sh`, suite PASS). Against the sheets in `production/concept/chapter4_v1/` and ART_BIBLE §2: no text, logos or plant faces; black sky, no haze or beams; every word is a live Screen or Label slot.

Second opinion: Codex (`gpt-6-astra`, high, read-only), shown the contact sheet and the vault-set capture. First pass 25 PASS, 3 FIX, all acted on: the LOD1 base plates of the return marker and the slope sign read square (now 12 segments), and the tether anchor's LOD1 had dropped its helix (kept, coarser). Second pass: 28 PASS.

| Asset | Verdict | Notes |
|---|---|---|
| EN_Garage_DockingPort_LOD0 | ✅ PASS | dock hatch 0.90 x 1.15 m (sill 0.45 m) with its vestibule panel (Screen, three state lamps, gauge); bellows collar meets VH_Rover's side hatch at 1.10 m (test checks the docked plane); HatchLeaf and DockCollar move; game LOD with collision |
| EN_Garage_DockingPort_LOD1 | ✅ PASS | dock hatch 0.90 x 1.15 m (sill 0.45 m) with its vestibule panel (Screen, three state lamps, gauge); bellows collar meets VH_Rover's side hatch at 1.10 m (test checks the docked plane); HatchLeaf and DockCollar move; Compatibility LOD, same silhouette |
| EN_Garage_BayWindow_LOD0 | ✅ PASS | 1.70 x 1.00 m window, navy room frame, white bay frame, two clear panes; handrail; game LOD with collision |
| EN_Garage_BayWindow_LOD1 | ✅ PASS | 1.70 x 1.00 m window, navy room frame, white bay frame, two clear panes; handrail; Compatibility LOD, same silhouette |
| EN_Garage_CargoLock_LOD0 | ✅ PASS | 0.72 x 0.56 m lock through the wall, LampDry and LampSafe, Screen; inner and outer doors never open together (en_garage.gd, tested); game LOD with collision |
| EN_Garage_CargoLock_LOD1 | ✅ PASS | 0.72 x 0.56 m lock through the wall, LampDry and LampSafe, Screen; inner and outer doors never open together (en_garage.gd, tested); Compatibility LOD, same silhouette |
| EN_Garage_SuitSealPanel_LOD0 | ✅ PASS | three seal gauges and lamps over blank plates (two suitports and the dock), Screen; no text; game LOD with collision |
| EN_Garage_SuitSealPanel_LOD1 | ✅ PASS | three seal gauges and lamps over blank plates (two suitports and the dock), Screen; no text; Compatibility LOD, same silhouette |
| EN_Garage_RouteBoard_LOD0 | ✅ PASS | 1.80 x 0.95 m Screen and three blank route cards on a rail; quilted kit panels; game LOD with collision |
| EN_Garage_RouteBoard_LOD1 | ✅ PASS | 1.80 x 0.95 m Screen and three blank route cards on a rail; quilted kit panels; Compatibility LOD, same silhouette |
| EN_Garage_DepartureBoard_LOD0 | ✅ PASS | portrait 0.74 x 1.20 m Screen with a status lamp; two side by side; game LOD with collision |
| EN_Garage_DepartureBoard_LOD1 | ✅ PASS | portrait 0.74 x 1.20 m Screen with a status lamp; two side by side; Compatibility LOD, same silhouette |
| EN_Garage_HandoverConsole_LOD0 | ✅ PASS | sloped desk with three screens (Screen, Screen2, Screen3: map, slope card, pad camera); blank keys; game LOD with collision |
| EN_Garage_HandoverConsole_LOD1 | ✅ PASS | sloped desk with three screens (Screen, Screen2, Screen3: map, slope card, pad camera); blank keys; Compatibility LOD, same silhouette |
| EN_Garage_CargoRack_LOD0 | ✅ PASS | sealed bins with blank plates and orange straps; the ledger tablet is Screen2; game LOD with collision |
| EN_Garage_CargoRack_LOD1 | ✅ PASS | sealed bins with blank plates and orange straps; the ledger tablet is Screen2; Compatibility LOD, same silhouette |
| EN_Garage_ReliefLocker_LOD0 | ✅ PASS | white double-door locker, blank plate, navy stripe; DoorL and DoorR swing out 110 deg; game LOD with collision |
| EN_Garage_ReliefLocker_LOD1 | ✅ PASS | white double-door locker, blank plate, navy stripe; DoorL and DoorR swing out 110 deg; Compatibility LOD, same silhouette |
| EN_Garage_BayFrame_LOD0 | ✅ PASS | steel portal, ribbed shield on the far wall and roof, LED flood panel, sintered floor slab (mount -0.06, top = finished floor); game LOD with collision |
| EN_Garage_BayFrame_LOD1 | ✅ PASS | steel portal, ribbed shield on the far wall and roof, LED flood panel, sintered floor slab (mount -0.06, top = finished floor); Compatibility LOD, same silhouette |
| EN_Garage_BayDoor_LOD0 | ✅ PASS | portal and drum; the ribbed panel coils into the drum (part kind scale), clear of the 4.41 m rover; game LOD with collision |
| EN_Garage_BayDoor_LOD1 | ✅ PASS | portal and drum; the ribbed panel coils into the drum (part kind scale), clear of the 4.41 m rover; Compatibility LOD, same silhouette |
| EN_Garage_BayEndWall_LOD0 | ✅ PASS | ribbed shield on the frame behind the EVA porch; game LOD with collision |
| EN_Garage_BayEndWall_LOD1 | ✅ PASS | ribbed shield on the frame behind the EVA porch; Compatibility LOD, same silhouette |
| EN_Garage_EVAPorch_LOD0 | ✅ PASS | grating deck at +1.40 m on sintered piers, rail with the suitport gate, stair along the far wall clear of the rover's wheels; game LOD with collision |
| EN_Garage_EVAPorch_LOD1 | ✅ PASS | grating deck at +1.40 m on sintered piers, rail with the suitport gate, stair along the far wall clear of the rover's wheels; Compatibility LOD, same silhouette |
| EN_Garage_Umbilical_LOD0 | ✅ PASS | navy post, orange connector head, hanging cable loop, status lamp; game LOD with collision |
| EN_Garage_Umbilical_LOD1 | ✅ PASS | navy post, orange connector head, hanging cable loop, status lamp; Compatibility LOD, same silhouette |
| EN_Garage_Plinth_LOD0 | ✅ PASS | sintered block 2 x 1.34 x 3.30 m with steel nosing and a navy kick strip; game LOD with collision |
| EN_Garage_Plinth_LOD1 | ✅ PASS | sintered block 2 x 1.34 x 3.30 m with steel nosing and a navy kick strip; Compatibility LOD, same silhouette |
| EN_Garage_BayMarkings_LOD0 | ✅ PASS | orange stall lines and white dashes only; no text, no collision; game LOD with collision |
| EN_Garage_BayMarkings_LOD1 | ✅ PASS | orange stall lines and white dashes only; no text, no collision; Compatibility LOD, same silhouette |
| EN_Garage_Berm_LOD0 | ✅ PASS | regolith overburden (M1-35 compacted set) with 35 deg sides, the door band clear, sintered headwall and wing walls; trimesh collision; game LOD with collision |
| EN_Garage_Berm_LOD1 | ✅ PASS | regolith overburden (M1-35 compacted set) with 35 deg sides, the door band clear, sintered headwall and wing walls; trimesh collision; Compatibility LOD, same silhouette |
| EN_ColdTrap_BeaconMast_LOD0 | ✅ PASS | 5 m guyed telescoping mast on a tripod, beacon head with Screen and status lamp, two retro bands (decision 9); game LOD with collision |
| EN_ColdTrap_BeaconMast_LOD1 | ✅ PASS | 5 m guyed telescoping mast on a tripod, beacon head with Screen and status lamp, two retro bands (decision 9); Compatibility LOD, same silhouette |
| EN_ColdTrap_ReturnMarker_LOD0 | ✅ PASS | 2 m pole, three retro bands, stiff flag plate (nothing flutters in vacuum); LOD1 base kept round after Codex's first pass; game LOD with collision |
| EN_ColdTrap_ReturnMarker_LOD1 | ✅ PASS | 2 m pole, three retro bands, stiff flag plate (nothing flutters in vacuum); LOD1 base kept round after Codex's first pass; Compatibility LOD, same silhouette |
| EN_ColdTrap_SlopeSign_LOD0 | ✅ PASS | blank Label face with a retro border on a 1.5 m post; LOD1 base kept round after Codex's first pass; game LOD with collision |
| EN_ColdTrap_SlopeSign_LOD1 | ✅ PASS | blank Label face with a retro border on a 1.5 m post; LOD1 base kept round after Codex's first pass; Compatibility LOD, same silhouette |
| EN_ColdTrap_ReferencePlate_LOD0 | ✅ PASS | four dry-standard tiles 0.30 m up on a low tripod, scanner socket; game LOD with collision |
| EN_ColdTrap_ReferencePlate_LOD1 | ✅ PASS | four dry-standard tiles 0.30 m up on a low tripod, scanner socket; Compatibility LOD, same silhouette |
| EN_ColdTrap_SampleStake_LOD0 | ✅ PASS | 0.60 m stake (0.10 m driven, mount), stiff orange tag with a blank Label, retro tip; game LOD with collision |
| EN_ColdTrap_SampleStake_LOD1 | ✅ PASS | 0.60 m stake (0.10 m driven, mount), stiff orange tag with a blank Label, retro tip; Compatibility LOD, same silhouette |
| EN_ColdTrap_TetherAnchor_LOD0 | ✅ PASS | helical anchor (0.40 m driven), bearing plate, orange D-ring; LOD1 keeps the helix after Codex's first pass; game LOD with collision |
| EN_ColdTrap_TetherAnchor_LOD1 | ✅ PASS | helical anchor (0.40 m driven), bearing plate, orange D-ring; LOD1 keeps the helix after Codex's first pass; Compatibility LOD, same silhouette |
| EN_ColdTrap_SurveyMarker2034_LOD0 | ✅ PASS | faded-yellow bands, blank archival tag (live text; nothing names Noor before CH05), 0.30 m driven; game LOD with collision |
| EN_ColdTrap_SurveyMarker2034_LOD1 | ✅ PASS | faded-yellow bands, blank archival tag (live text; nothing names Noor before CH05), 0.30 m driven; Compatibility LOD, same silhouette |
| PR_VaultCase | ✅ PASS | rebuilt hinged in the installed case's 0.60 x 0.39 m footprint: ID window, recessed probe socket, latches, 12 capped wells with blank tabs, Lid with Label_Lid underneath (clue 15); exterior_terrain.json LOC-10 re-derived for it; prop |
| PR_VaultProbe | ✅ PASS | 0.45 m thermal wand with a Screen in the grip and a coiled cable; prop |
| PR_VaultCarrier | ✅ PASS | cradle with two lift handles and a tether eye; the MLI sleeve reads dark in a sky-less studio, as foil does under a black lunar sky (the room adds reflection probes); prop |
| PR_RoverCargoMount | ✅ PASS | latch rails, latch with its orange position flag, separate lock pin with its own lamp (S08: position vs lock); prop |

## M3-6A eclipse power props review — 9 November 2026, Sadman/antigravity

Inspected `production/qa/evidence/M3-6A_contact.png`, `M3-6A_lods.png`, and the Godot captures `production/qa/evidence/M3-6A_*.png` (`M3-6A_board_plan.png`, `M3-6A_camera_exterior.png`, `M3-6A_monitor_ring.png`, `M3-6A_monitor_screen_ingress.png`, `M3-6A_monitor_screen_no_signal.png`, `M3-6A_monitor_screen_ring.png`, `M3-6A_panel_f2_isolated.png`, `M3-6A_panel_f2_tripped.png`, `M3-6A_power_room.png`, `M3-6A_props_lod0.png`, `M3-6A_props_lod1.png`, `M3-6A_s04_floods_on.png`, `M3-6A_s04_guide_only.png`) against `production/ART_BIBLE.md` §§2, 3 and 7 and the story (`STORY_FULL.md` EX-CH06-S01..S12, `08_PUZZLE_DESIGNS.md` P-11/P-12): palette tokens (suit white, navy bezel/trim, signal orange isolation boundary and marker tape, amber guide channel), zero baked text or logos on any 3D mesh (every label is a blank plate for `Label3D` or a live `Screen` material), English only, metre scale with floor-seated pivots, LOD1 retains silhouettes, colour regions and moving-part/screen nodes at ~50 % triangles on 512 px shared kit textures, and the monitor's live eclipse picture (`eclipse_monitor_screen.gd`) shows a black sky, Earth's dark disc ~3.5x the Sun's angular diameter as seen from the Moon, the red refracted atmospheric rim at totality (`M3-6A_monitor_screen_ring.png`), the conceptual inset explicitly labelled `"Conceptual diagram - not to scale - not a map of Earth"`, `"Eclipse date: 12 Jan 2047 - NASA eclipse catalog (checked)"`, and `"Aurora's local timing and view: scenario, awaiting verified geometry"`. All 18 GLBs pass the automated gate in `production/review/asset_verification.md`.

| Asset | Verdict | Notes |
|---|---|---|
| PR_EclipseBoard_LOD0 | ✅ PASS | 1.602 x 1.000 m navy/white allocation board: 5 segment card slots, 4 service rows, 20 magnetic tag sockets, 5 warning lamps, live forecast strip (`Screen`), 11 blank label plates (no baked text); game LOD with collision |
| PR_EclipseBoard_LOD1 | ✅ PASS | Compatibility LOD (902 tris vs 1366): same grid, slots, lamps and screen node, 512 px shared kit textures, no collision |
| PR_SegmentCard_LOD0 | ✅ PASS | 0.200 x 0.130 m card with colour band (`Band`) and blank `Label` plate for the five eclipse phases; game LOD with collision |
| PR_SegmentCard_LOD1 | ✅ PASS | Compatibility LOD (52 tris vs 172): same silhouette, colour band and label slot, no collision |
| PR_ServiceTag_LOD0 | ✅ PASS | 0.150 x 0.075 m magnetic service tag with role/branch colour band and blank `Label` plate; game LOD with collision |
| PR_ServiceTag_LOD1 | ✅ PASS | Compatibility LOD (52 tris vs 136): same silhouette, colour band and label slot, no collision |
| PR_GuideLightBranch_LOD0 | ✅ PASS | 0.990 m junction box, status lamp, blank branch label, vertical riser with Kai's orange marker tape (`MarkerTape`), and first 0.82 m of amber LED channel (`Diffuser`); game LOD with collision |
| PR_GuideLightBranch_LOD1 | ✅ PASS | Compatibility LOD (326 tris vs 598): preserves junction box, orange marker tape and amber diffuser channel, no collision |
| PR_GuideLightRun_LOD0 | ✅ PASS | 1.000 m modular low-wall amber LED channel with `Diffuser` and `EndCap` that chains on the 1 m kit grid; game LOD with collision |
| PR_GuideLightRun_LOD1 | ✅ PASS | Compatibility LOD (82 tris vs 106): same 1 m channel silhouette and diffuser slot, no collision |
| PR_DecorativeFlood_LOD0 | ✅ PASS | 0.286 m finned dark housing on a tilt yoke aimed 25 deg down (`Head`, `Lens`), contrasting with the low amber guide run in S04; game LOD with collision |
| PR_DecorativeFlood_LOD1 | ✅ PASS | Compatibility LOD (192 tris vs 404): cooling fins dropped, same yoke, head and lens silhouette, no collision |
| PR_ProtectedBusPanel_LOD0 | ✅ PASS | 0.900 x 2.000 m cabinet: mimic diagram, orange isolation boundary, sealed clear `ProtectedGuard` over the 4 essential breakers with `SealTag`, `TestSwitch`, `F2Isolator`, `F2Breaker`, `F2TestButton`, `FloodBreaker`, 8 lamps, 2 live screens and 21 blank label plates; game LOD with collision |
| PR_ProtectedBusPanel_LOD1 | ✅ PASS | Compatibility LOD (1994 tris vs 3238): keeps all moving switches/breakers, guard, lamps and screens with fewer bevels, no collision |
| PR_FilteredCamera_LOD0 | ✅ PASS | 1.829 m exterior mast camera: `Pan` and `Tilt` head, MLI-wrapped body, sun hood with hinged solar `Filter` (swings clear at totality), F2 junction box with status lamps and cable; game LOD with collision |
| PR_FilteredCamera_LOD1 | ✅ PASS | Compatibility LOD (762 tris vs 1370): keeps mast, pan/tilt head, hinged solar filter and F2 box silhouette, no collision |
| PR_EclipseMonitor_LOD0 | ❌ FIX | 0.620 x 0.600 m desk display with navy bezel, `Display` tilt, `HoldButton`, status lamp, blank label plate, and `Screen_Main` displaying the verified eclipse camera feed and conceptual limb-refraction inset; game LOD with collision. The shared live screen draws a faint red Earth-limb rim in `M3-6A_monitor_screen_ingress.png` before totality; `eclipse_camera_view.gdshader` adds `rim * gain` at every phase. Geometry and inset pass; live screen needs M4-16. |
| PR_EclipseMonitor_LOD1 | ❌ FIX | Compatibility LOD (214 tris vs 366): same stand, bezel, screen and button nodes, no collision. The same live screen is used by both LODs, so the ingress-rim defect also applies here; geometry passes. M4-16. |

**Asif/Codex follow-up, 9 Nov 2026:** The 18 GLBs retain the automated-gate and geometry findings above. The ingress capture shows a red Earth rim while the Sun remains exposed. The live shader draws that rim without checking the `ring_visible()` totality condition. The first 16 verdicts remain PASS; the two monitor verdicts are FIX until Sadman resolves M4-16.
