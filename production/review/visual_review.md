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
