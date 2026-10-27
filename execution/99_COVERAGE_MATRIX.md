# Complete task index and coverage matrix

Prepared against`ca01433`on 27 October 2026. Every linked file is a separate execution prompt; implementation status is not implied.

## Coverage summary

- 75 asset registry entries each have one ASSET prompt; 22 additional handbook-required families cover missing tools/outfits/kits.
- 32 mandatory missions embed all 96 final scenes and 385 dialogue lines.
- 16 scientific puzzle prompts, including exact numeric appendices.
- 16 UI component families; 18 final cutscenes.
- 10 voice groups cover 385 exact CSV rows; 12 music cues; 35 SFX.
- 23 shared system tasks; 15 source-evidence artifacts; 7 upgrade pairs; 4 ending packets; 3 animation families; effects, independent QA and release packets.

## Task dependencies

Read the [exact ownership/dependency map](07_DEPENDENCY_AND_OWNERSHIP_MAP.md) and [source revision receipt](08_SOURCE_REVISION_RECEIPT.md) before assigning concurrent work.

Execute Phase 0 interfaces first; Chapter 1 vertical slice comes next; extend through the 32 ordered missions before full release QA. Assets/audio have parallel-ready work only when exact design/input approvals are present. See[06_EXECUTION_BOARD.md](06_EXECUTION_BOARD.md).

## Shared runtime

|Task|Prompt|Outcome|
|---|---|---|
|`SYS01`|[Toolchain, repository and portable validation](SYS_01_TOOLCHAIN_AND_REPO.md)|Audit the actual checkout and establish reproducible Godot/asset/media checks on the execution host.|
|`SYS02`|[Final campaign content import and validation](SYS_02_CAMPAIGN_CONTENT.md)|Import the final eight-chapter story into engine-readable, revisioned content without rewriting IDs or dialogue.|
|`SYS03`|[Campaign director, state and idempotent progression](SYS_03_CAMPAIGN_STATE.md)|Implement the single authoritative expedition state and gate the 32 mandatory missions from actual predicates.|
|`SYS04`|[Pure resource simulation, forecast and commit](SYS_04_SIMULATION_PREVIEW.md)|Implement one deterministic transition engine for canonical resources, timing, profiles and earned modifiers.|
|`SYS05`|[World interaction, focus and physical action transactions](SYS_05_INTERACTION_TRANSACTIONS.md)|Connect current player input to inspect/use/transfer/verify/confirm actions and shared state.|
|`SYS06`|[Dialogue, captions, origin and acquired knowledge](SYS_06_DIALOGUE_KNOWLEDGE.md)|Deliver the exact 385 line script with spoiler-safe speaker identities, message origin and accessible text.|
|`SYS07`|[Atomic saves, checkpoints, retries and migration](SYS_07_SAVE_CHECKPOINTS.md)|Implement reliable campaign persistence and respectful recovery for every mission/puzzle boundary.|
|`SYS08`|[World locations, roster, travel and explicit time transitions](SYS_08_WORLD_ROSTER_TIME.md)|Keep every actor, plant and message in the correct physical/story location through authored viewpoint cuts.|
|`SYS09`|[Current player locomotion, camera, holds and contact integration](SYS_09_PLAYER_ANIMATION.md)|Finish and integrate the existing player rather than replacing its reviewed movement system.|
|`SYS10`|[Anime facial atlas, speech, gaze, hair and expression runtime](SYS_10_CHARACTER_FACE_HAIR.md)|Integrate drawn eye/mouth face layers and hair with the existing character renderer and dialogue.|
|`SYS11`|[Shared anime materials, readable lighting and art integration](SYS_11_TOON_LIGHTING.md)|Unify characters, plants, props and environments under the current shader/art contract.|
|`SYS12`|[Collision, navigation, doors and safe traversable spaces](SYS_12_PHYSICS_NAVIGATION.md)|Make assembled rooms and routes physically navigable with correct pressure/interlock boundaries.|
|`SYS13`|[Offline scientific evidence pipeline, source cards and qualified displays](SYS_13_SCIENCE_DATA.md)|Build genuine source-backed charts/maps and correctly labelled training fallbacks.|
|`SYS14`|[Persistent upgrades, inventory and dated logistics](SYS_14_UPGRADES_LOGISTICS.md)|Conserve seeds/water/supplies and apply correctly acquired upgrades across the full campaign.|
|`SYS15`|[Solo, Family, Cadet, Engineer and Class role-sharing modes](SYS_15_ROLE_MODES.md)|Expose the same complete campaign through accessible role-sharing and educational modes.|
|`SYS16`|[Scene streaming, performance budgets and runtime resilience](SYS_16_PERFORMANCE_STREAMING.md)|Make the campaign stable on the agreed target hardware with measured budgets.|
|`SYS17`|[Audio buses, cinematic playback, captions and pause/skip](SYS_17_AUDIO_CINEMATIC_RUNTIME.md)|Provide one runtime owner for voice/music/SFX/OGV playback and narrative acknowledgement.|
|`SYS18`|[Registry, provenance and truthful production status](SYS_18_DOCUMENTATION_REGISTRY.md)|Reconcile drift and keep task evidence, manifests and handoffs consistent with actual outputs.|
|`SYS19`|[Application bootstrap, main scene and complete launch flow](SYS_19_BOOTSTRAP_MAIN_SCENE.md)|Create the actual launch able game entry and connect menus, saved progress and campaign scenes.|
|`SYS20`|[Plant identity, dated lifecycle, care and viability service](SYS_20_PLANT_BIOLOGY.md)|Implement the shared biological state model that drives original plants, descendants, crops and cotton.|
|`SYS21`|[Companion anchors, teamwork and contextual support](SYS_21_COMPANION_BEHAVIOUR.md)|Make non-controlled crew feel present and useful without bypassing player agency or knowledge gates.|
|`SYS22`|[Shared puzzle host, input adapters and progressive hints](SYS_22_PUZZLE_HOST_HINTS.md)|Provide one reusable puzzle framework consumed by the sixteen puzzle implementations.|
|`SYS23`|[Portable test runner, fixtures and build validation](SYS_23_PORTABLE_TEST_HARNESS.md)|Replace environment-dependent verification gaps with a reproducible bounded test work flow.|

## Asset family

|Task|Prompt|Outcome|
|---|---|---|
|`CH_Cadet_DutyLayer`|[CH_Cadet_Duty Layer](ASSET_CH_Cadet_DutyLayer.md)|Finish/verify `CH_Cadet_DutyLayer` within the approved current character/screen/outfit family, preserving identity and all already delivered runtime work.|
|`CH_Ferreira_Duty`|[CH_Ferreira_Duty](ASSET_CH_Ferreira_Duty.md)|Finish/verify `CH_Ferreira_Duty` within the approved current character/screen/outfit family, preserving identity and all already delivered runtime work.|
|`CH_Noor`|[CH_Noor](ASSET_CH_Noor.md)|Finish/verify `CH_Noor` within the approved current character/screen/outfit family, preserving identity and all already delivered runtime work.|
|`CH_Rao`|[CH_Rao](ASSET_CH_Rao.md)|Finish/verify `CH_Rao` within the approved current character/screen/outfit family, preserving identity and all already delivered runtime work.|
|`CH_Amara`|[CH_Amara](ASSET_CH_Amara.md)|Finish/verify `CH_Amara` within the approved current character/screen/outfit family, preserving identity and all already delivered runtime work.|
|`CH_Ferreira`|[CH_Ferreira](ASSET_CH_Ferreira.md)|Finish/verify `CH_Ferreira` within the approved current character/screen/outfit family, preserving identity and all already delivered runtime work.|
|`CH_Kai`|[CH_Kai](ASSET_CH_Kai.md)|Finish/verify `CH_Kai` within the approved current character/screen/outfit family, preserving identity and all already delivered runtime work.|
|`CH_Mei`|[CH_Mei](ASSET_CH_Mei.md)|Finish/verify `CH_Mei` within the approved current character/screen/outfit family, preserving identity and all already delivered runtime work.|
|`CH_Rafi`|[CH_Rafi](ASSET_CH_Rafi.md)|Finish/verify `CH_Rafi` within the approved current character/screen/outfit family, preserving identity and all already delivered runtime work.|
|`EN_Airlock`|[EN_Airlock](ASSET_EN_Airlock.md)|Assemble/finish `EN_Airlock` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`EN_ColdTrap`|[EN_Cold Trap](ASSET_EN_ColdTrap.md)|Assemble/finish `EN_ColdTrap` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`EN_Commons`|[EN_Commons](ASSET_EN_Commons.md)|Assemble/finish `EN_Commons` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`EN_CorridorSegment`|[EN_Corridor Segment](ASSET_EN_CorridorSegment.md)|Assemble/finish `EN_CorridorSegment` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`EN_EarthDesk`|[EN_Earth Desk](ASSET_EN_EarthDesk.md)|Assemble/finish `EN_EarthDesk` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`EN_Exterior`|[EN_Exterior](ASSET_EN_Exterior.md)|Assemble/finish `EN_Exterior` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`EN_ExteriorModule`|[EN_Exterior Module](ASSET_EN_ExteriorModule.md)|Assemble/finish `EN_ExteriorModule` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`EN_Garage`|[EN_Garage](ASSET_EN_Garage.md)|Assemble/finish `EN_Garage` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`EN_Garden`|[EN_Garden](ASSET_EN_Garden.md)|Assemble/finish `EN_Garden` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`EN_HabitatKit`|[EN_Habitat Kit](ASSET_EN_HabitatKit.md)|Assemble/finish `EN_HabitatKit` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`EN_MalapertSummit`|[EN_Malapert Summit](ASSET_EN_MalapertSummit.md)|Assemble/finish `EN_MalapertSummit` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`EN_NoorRooftop`|[EN_Noor Rooftop](ASSET_EN_NoorRooftop.md)|Assemble/finish `EN_NoorRooftop` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`EN_RelayRoad`|[EN_Relay Road](ASSET_EN_RelayRoad.md)|Assemble/finish `EN_RelayRoad` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`EN_SafeRoom`|[EN_Safe Room](ASSET_EN_SafeRoom.md)|Assemble/finish `EN_SafeRoom` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`EN_ServiceRooms`|[EN_Service Rooms](ASSET_EN_ServiceRooms.md)|Assemble/finish `EN_ServiceRooms` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`EN_SolarMast`|[EN_Solar Mast](ASSET_EN_SolarMast.md)|Assemble/finish `EN_SolarMast` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`EN_ZeroAnnex`|[EN_Zero Annex](ASSET_EN_ZeroAnnex.md)|Assemble/finish `EN_ZeroAnnex` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`PL_Alo_Sprout`|[PL_Alo_Sprout](ASSET_PL_Alo_Sprout.md)|Finish/verify `PL_Alo_Sprout` with correct botany, dated lifecycle, identifiable lineage and pressure-safe presentation.|
|`PL_Cotton_Seedling`|[PL_Cotton_Seedling](ASSET_PL_Cotton_Seedling.md)|Finish/verify `PL_Cotton_Seedling` with correct botany, dated lifecycle, identifiable lineage and pressure-safe presentation.|
|`PL_Descendants`|[PL_Descendants](ASSET_PL_Descendants.md)|Finish/verify `PL_Descendants` with correct botany, dated lifecycle, identifiable lineage and pressure-safe presentation.|
|`PL_Alo_Bloom`|[PL_Alo_Bloom](ASSET_PL_Alo_Bloom.md)|Finish/verify `PL_Alo_Bloom` with correct botany, dated lifecycle, identifiable lineage and pressure-safe presentation.|
|`PL_Alo_Bud`|[PL_Alo_Bud](ASSET_PL_Alo_Bud.md)|Finish/verify `PL_Alo_Bud` with correct botany, dated lifecycle, identifiable lineage and pressure-safe presentation.|
|`PL_Alo_Pods`|[PL_Alo_Pods](ASSET_PL_Alo_Pods.md)|Finish/verify `PL_Alo_Pods` with correct botany, dated lifecycle, identifiable lineage and pressure-safe presentation.|
|`PL_Cotton_Young`|[PL_Cotton_Young](ASSET_PL_Cotton_Young.md)|Finish/verify `PL_Cotton_Young` with correct botany, dated lifecycle, identifiable lineage and pressure-safe presentation.|
|`PL_CropRack`|[PL_Crop Rack](ASSET_PL_CropRack.md)|Finish/verify `PL_CropRack` with correct botany, dated lifecycle, identifiable lineage and pressure-safe presentation.|
|`PL_Tara_Bloom`|[PL_Tara_Bloom](ASSET_PL_Tara_Bloom.md)|Finish/verify `PL_Tara_Bloom` with correct botany, dated lifecycle, identifiable lineage and pressure-safe presentation.|
|`PL_ZeroSeedlingTray`|[PL_Zero Seedling Tray](ASSET_PL_ZeroSeedlingTray.md)|Finish/verify `PL_ZeroSeedlingTray` with correct botany, dated lifecycle, identifiable lineage and pressure-safe presentation.|
|`PR_Helmet_Roles`|[PR_Helmet_Roles](ASSET_PR_Helmet_Roles.md)|Finish/verify `PR_Helmet_Roles` as a reusable story-correct interactable prop.|
|`PR_ImpactMonitor`|[PR_Impact Monitor](ASSET_PR_ImpactMonitor.md)|Finish/verify `PR_ImpactMonitor` as a reusable story-correct interactable prop.|
|`PR_PaperBee`|[PR_Paper Bee](ASSET_PR_PaperBee.md)|Finish/verify `PR_PaperBee` as a reusable story-correct interactable prop.|
|`PR_PressedPetal`|[PR_Pressed Petal](ASSET_PR_PressedPetal.md)|Finish/verify `PR_PressedPetal` as a reusable story-correct interactable prop.|
|`PR_AnnexDrum`|[PR_Annex Drum](ASSET_PR_AnnexDrum.md)|Finish/verify `PR_AnnexDrum` as a reusable story-correct interactable prop.|
|`PR_BatteryJar`|[PR_Battery Jar](ASSET_PR_BatteryJar.md)|Finish/verify `PR_BatteryJar` as a reusable story-correct interactable prop.|
|`PR_ControlConsole`|[PR_Control Console](ASSET_PR_ControlConsole.md)|Finish/verify `PR_ControlConsole` as a reusable story-correct interactable prop.|
|`PR_CrewBunk`|[PR_Crew Bunk](ASSET_PR_CrewBunk.md)|Finish/verify `PR_CrewBunk` as a reusable story-correct interactable prop.|
|`PR_CrewSeat`|[PR_Crew Seat](ASSET_PR_CrewSeat.md)|Finish/verify `PR_CrewSeat` as a reusable story-correct interactable prop.|
|`PR_Dosimeter`|[PR_Dosimeter](ASSET_PR_Dosimeter.md)|Finish/verify `PR_Dosimeter` as a reusable story-correct interactable prop.|
|`PR_Glovebox`|[PR_Glovebox](ASSET_PR_Glovebox.md)|Finish/verify `PR_Glovebox` as a reusable story-correct interactable prop.|
|`PR_GrowthChamber`|[PR_Growth Chamber](ASSET_PR_GrowthChamber.md)|Finish/verify `PR_GrowthChamber` as a reusable story-correct interactable prop.|
|`PR_HandLight`|[PR_Hand Light](ASSET_PR_HandLight.md)|Finish/verify `PR_HandLight` as a reusable story-correct interactable prop.|
|`PR_HatchDoor`|[PR_Hatch Door](ASSET_PR_HatchDoor.md)|Finish/verify `PR_HatchDoor` as a reusable story-correct interactable prop.|
|`PR_Helmet`|[PR_Helmet](ASSET_PR_Helmet.md)|Finish/verify `PR_Helmet` as a reusable story-correct interactable prop.|
|`PR_IceScanner`|[PR_Ice Scanner](ASSET_PR_IceScanner.md)|Finish/verify `PR_IceScanner` as a reusable story-correct interactable prop.|
|`PR_MalapertRelay`|[PR_Malapert Relay](ASSET_PR_MalapertRelay.md)|Finish/verify `PR_MalapertRelay` as a reusable story-correct interactable prop.|
|`PR_ManualGauge`|[PR_Manual Gauge](ASSET_PR_ManualGauge.md)|Finish/verify `PR_ManualGauge` as a reusable story-correct interactable prop.|
|`PR_MissionTable`|[PR_Mission Table](ASSET_PR_MissionTable.md)|Finish/verify `PR_MissionTable` as a reusable story-correct interactable prop.|
|`PR_Mug`|[PR_Mug](ASSET_PR_Mug.md)|Finish/verify `PR_Mug` as a reusable story-correct interactable prop.|
|`PR_OxygenUnit`|[PR_Oxygen Unit](ASSET_PR_OxygenUnit.md)|Finish/verify `PR_OxygenUnit` as a reusable story-correct interactable prop.|
|`PR_PollinationKit`|[PR_Pollination Kit](ASSET_PR_PollinationKit.md)|Finish/verify `PR_PollinationKit` as a reusable story-correct interactable prop.|
|`PR_PowerPanel`|[PR_Power Panel](ASSET_PR_PowerPanel.md)|Finish/verify `PR_PowerPanel` as a reusable story-correct interactable prop.|
|`PR_Recorder2034`|[PR_Recorder 2034](ASSET_PR_Recorder2034.md)|Finish/verify `PR_Recorder2034` as a reusable story-correct interactable prop.|
|`PR_RelayController`|[PR_Relay Controller](ASSET_PR_RelayController.md)|Finish/verify `PR_RelayController` as a reusable story-correct interactable prop.|
|`PR_RepairClamp`|[PR_Repair Clamp](ASSET_PR_RepairClamp.md)|Finish/verify `PR_RepairClamp` as a reusable story-correct interactable prop.|
|`PR_SampleHolder`|[PR_Sample Holder](ASSET_PR_SampleHolder.md)|Finish/verify `PR_SampleHolder` as a reusable story-correct interactable prop.|
|`PR_SeedCase`|[PR_Seed Case](ASSET_PR_SeedCase.md)|Finish/verify `PR_SeedCase` as a reusable story-correct interactable prop.|
|`PR_SeedPacket`|[PR_Seed Packet](ASSET_PR_SeedPacket.md)|Finish/verify `PR_SeedPacket` as a reusable story-correct interactable prop.|
|`PR_SupplyBundles`|[PR_Supply Bundles](ASSET_PR_SupplyBundles.md)|Finish/verify `PR_SupplyBundles` as a reusable story-correct interactable prop.|
|`PR_SurveyBeacon`|[PR_Survey Beacon](ASSET_PR_SurveyBeacon.md)|Finish/verify `PR_SurveyBeacon` as a reusable story-correct interactable prop.|
|`PR_UplinkFeedthrough`|[PR_Uplink Feed through](ASSET_PR_UplinkFeedthrough.md)|Finish/verify `PR_UplinkFeedthrough` as a reusable story-correct interactable prop.|
|`PR_VaultCase`|[PR_Vault Case](ASSET_PR_VaultCase.md)|Finish/verify `PR_VaultCase` as a reusable story-correct interactable prop.|
|`PR_WaterValve`|[PR_Water Valve](ASSET_PR_WaterValve.md)|Finish/verify `PR_WaterValve` as a reusable story-correct interactable prop.|
|`PR_WaterWallPanel`|[PR_Water Wall Panel](ASSET_PR_WaterWallPanel.md)|Finish/verify `PR_WaterWallPanel` as a reusable story-correct interactable prop.|
|`UI_Kit`|[UI_Kit](ASSET_UI_Kit.md)|Finish the shared UI art/widget kit as an engine-integrated English-only system used by the 16 screen prompts.|
|`VH_ReliefLander`|[VH_Relief Lander](ASSET_VH_ReliefLander.md)|Finish/verify `VH_ReliefLander` for its actual transport/screen role and safe scene interaction.|
|`VH_Rover`|[VH_Rover](ASSET_VH_Rover.md)|Finish/verify `VH_Rover` for its actual transport/screen role and safe scene interaction.|
|`VH_ZeroAscent`|[VH_Zero Ascent](ASSET_VH_ZeroAscent.md)|Finish/verify `VH_ZeroAscent` for its actual transport/screen role and safe scene interaction.|
|`CH_Cadet_EVA`|[CH_Cadet_EVA](ASSET_CH_Cadet_EVA.md)|Finish/verify `CH_Cadet_EVA` within the approved current character/screen/outfit family, preserving identity and all already delivered runtime work.|
|`EN_Fabrication`|[EN_Fabrication](ASSET_EN_Fabrication.md)|Assemble/finish `EN_Fabrication` as the correct reusable world space or modular piece, with playable routes and current anime presentation.|
|`UI_Fonts_Icons`|[UI_Fonts_Icons](ASSET_UI_Fonts_Icons.md)|Finish the shared UI art/widget kit as an engine-integrated English-only system used by the 16 screen prompts.|
|`PR_CalibrationStation`|[PR_Calibration Station](ASSET_PR_CalibrationStation.md)|Finish/verify `PR_CalibrationStation` as a reusable story-correct interactable prop.|
|`PR_PlantingCassettes`|[PR_Planting Cassettes](ASSET_PR_PlantingCassettes.md)|Finish/verify `PR_PlantingCassettes` as a reusable story-correct interactable prop.|
|`PR_CharterRosterKit`|[PR_Charter Roster Kit](ASSET_PR_CharterRosterKit.md)|Finish/verify `PR_CharterRosterKit` as a reusable story-correct interactable prop.|
|`PR_LineageBoard`|[PR_Lineage Board](ASSET_PR_LineageBoard.md)|Finish/verify `PR_LineageBoard` as a reusable story-correct interactable prop.|
|`PR_SeedCountingTray`|[PR_Seed Counting Tray](ASSET_PR_SeedCountingTray.md)|Finish/verify `PR_SeedCountingTray` as a reusable story-correct interactable prop.|
|`PR_MaturityDryingStation`|[PR_Maturity Drying Station](ASSET_PR_MaturityDryingStation.md)|Finish/verify `PR_MaturityDryingStation` as a reusable story-correct interactable prop.|
|`PR_AnnexViewingPort`|[PR_Annex Viewing Port](ASSET_PR_AnnexViewingPort.md)|Finish/verify `PR_AnnexViewingPort` as a reusable story-correct interactable prop.|
|`PR_DiagnosticManifold`|[PR_Diagnostic Manifold](ASSET_PR_DiagnosticManifold.md)|Finish/verify `PR_DiagnosticManifold` as a reusable story-correct interactable prop.|
|`PR_RecorderMetadataKit`|[PR_Recorder Metadata Kit](ASSET_PR_RecorderMetadataKit.md)|Finish/verify `PR_RecorderMetadataKit` as a reusable story-correct interactable prop.|
|`PR_TransferInterlock`|[PR_Transfer Interlock](ASSET_PR_TransferInterlock.md)|Finish/verify `PR_TransferInterlock` as a reusable story-correct interactable prop.|
|`PR_FlowerTeachingModel`|[PR_Flower Teaching Model](ASSET_PR_FlowerTeachingModel.md)|Finish/verify `PR_FlowerTeachingModel` as a reusable story-correct interactable prop.|
|`PR_QuakeBraceMarkers`|[PR_Quake Brace Markers](ASSET_PR_QuakeBraceMarkers.md)|Finish/verify `PR_QuakeBraceMarkers` as a reusable story-correct interactable prop.|
|`PR_ImpactCamera`|[PR_Impact Camera](ASSET_PR_ImpactCamera.md)|Finish/verify `PR_ImpactCamera` as a reusable story-correct interactable prop.|
|`PR_MaintenanceKit`|[PR_Maintenance Kit](ASSET_PR_MaintenanceKit.md)|Finish/verify `PR_MaintenanceKit` as a reusable story-correct interactable prop.|
|`PR_EclipseCamera`|[PR_Eclipse Camera](ASSET_PR_EclipseCamera.md)|Finish/verify `PR_EclipseCamera` as a reusable story-correct interactable prop.|
|`PR_ArchiveEvidenceKit`|[PR_Archive Evidence Kit](ASSET_PR_ArchiveEvidenceKit.md)|Finish/verify `PR_ArchiveEvidenceKit` as a reusable story-correct interactable prop.|
|`PR_RoverCargoKit`|[PR_Rover Cargo Kit](ASSET_PR_RoverCargoKit.md)|Finish/verify `PR_RoverCargoKit` as a reusable story-correct interactable prop.|
|`PR_TetherRepairTools`|[PR_Tether Repair Tools](ASSET_PR_TetherRepairTools.md)|Finish/verify `PR_TetherRepairTools` as a reusable story-correct interactable prop.|
|`PR_HistoricalCottonDisplay`|[PR_Historical Cotton Display](ASSET_PR_HistoricalCottonDisplay.md)|Finish/verify `PR_HistoricalCottonDisplay` as a reusable story-correct interactable prop.|

## Mandatory mission

|Task|Prompt|Outcome|
|---|---|---|
|`EX-M0101`|[Give the Station a Crew](MISSION_EX_M0101.md)|Commission, rehearse independent safety and inspect the seed evidence. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0102`|[Two Plants, One Night Plan](MISSION_EX_M0102.md)|Plant, sustain dated care and understand the night timeline. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0103`|[Prepare While It Is Light](MISSION_EX_M0103.md)|Store air, rehearse shielding and compare the dark-shift plan. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0104`|[Keep the Promise Until Dawn](MISSION_EX_M0104.md)|Respond, restore water and earn the first-bloom ending. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0201`|[Understand the Missing Bee](MISSION_EX_M0201.md)|Identify compatible partners, transfer structures and the full contained route. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0202`|[Carry the Future Carefully](MISSION_EX_M0202.md)|Complete three reciprocal cycles over seven care dates and record a testable trait prediction. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0203`|[Make an Old Record Useful](MISSION_EX_M0203.md)|Respect biological timing, collect provenance and reconstruct the recorder copy. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0204`|[Hear, Ask and Re prior it is e](MISSION_EX_M0204.md)|Interpret the archive honestly, send evidence and respond safely to the quake. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0301`|[Find the Falling Line](MISSION_EX_M0301.md)|Compare independent instruments and approve the smallest supported isolation. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0302`|[Repair Before Discovery](MISSION_EX_M0302.md)|Verify the service repair, reconcile records and inspect the known annex by camera. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0303`|[Read What Was Unfinished](MISSION_EX_M0303.md)|Enter safely, establish seedling-stage history, verify map provenance and begin mature-pod drying. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0304`|[Let the Garden Continue](MISSION_EX_M0304.md)|Harvest and allocate 42 seeds, plant 12 and protect 30, then account for care and descendants through October. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0401`|[Make the Old Map Current](MISSION_EX_M0401.md)|Test the trait prediction, split ledgers correctly and justify a safe route. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0402`|[Measure Before Claiming](MISSION_EX_M0402.md)|Verify the beacon chain, calibrate sample evidence and identify the deposited vault. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0403`|[Recover Without Ruining](MISSION_EX_M0403.md)|Keep the biological seal intact, secure cargo and return with supported reserves. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0404`|[Bring the Question Home](MISSION_EX_M0404.md)|Stabilise and inventory 12 specimens, send the inscription and prepare for Ferreira's actual arrival. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0501`|[The Engineer Comes Home](MISSION_EX_M0501.md)|Welcome Ferreira and reconstruct the evacuation. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0502`|[The Parts We Left Unsaid](MISSION_EX_M0502.md)|Resolve biological and personal misunderstandings. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0503`|[A Moon That Keeps Records](MISSION_EX_M0503.md)|Verify observations, maintain systems and bound claims. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0504`|[Permission to Answer](MISSION_EX_M0504.md)|Identify Noor, invite contact and plant cotton. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0601`|[A Plan for Darkness](MISSION_EX_M0601.md)|Turn human needs and service dependencies into one checked allocation. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0602`|[The Plan We Share](MISSION_EX_M0602.md)|Compare options, rehearse isolation and collect actual readiness reports. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0603`|[All the Sunrises](MISSION_EX_M0603.md)|Observe with honest labels and communicate within a valid path. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0604`|[The Light That Returns](MISSION_EX_M0604.md)|Restore the camera, account for recovery and hand over sustained monitoring. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0701`|[Your Call, Cadets](MISSION_EX_M0701.md)|Distinguish source evidence and integrate the five-person forecast. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0702`|[What Gets the Last Drop](MISSION_EX_M0702.md)|Protect founder stock, verify occupants and execute the first wave. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0703`|[What We Carry](MISSION_EX_M0703.md)|Complete the remaining waves and diagnose the external failure. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0704`|[The Days That Make a Journey](MISSION_EX_M0704.md)|Maintain stable local operations and physically prepare the relay bypass. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0801`|[The Long Road](MISSION_EX_M0801.md)|Provision the full round trip, validate terrain and reach the failed marker. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0802`|[Two Teams, One Night](MISSION_EX_M0802.md)|Restore the road chain while the home team verifies its changing-occupancy plan. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0803`|[Both Ends of the Light](MISSION_EX_M0803.md)|Replace the controller and prove both communication legs and exact data. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|
|`EX-M0804`|[From Last Light to First Light](MISSION_EX_M0804.md)|Restore chosen human contact, return on time and verify the continuing garden. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.|

## Scientific puzzle

|Task|Prompt|Outcome|
|---|---|---|
|`P-01`|[Commission and Plant](PUZZLE_P01.md)|Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.|
|`P-02`|[Seven Shifts, One Night](PUZZLE_P02.md)|Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.|
|`P-03`|[Alo Meets Tara](PUZZLE_P03.md)|Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.|
|`P-04`|[Recorder Reconstruction](PUZZLE_P04.md)|Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.|
|`P-05`|[Find the Falling Pressure](PUZZLE_P05.md)|Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.|
|`P-06`|[A Harvest With a Future](PUZZLE_P06.md)|Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.|
|`P-07`|[Survey and Return](PUZZLE_P07.md)|Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.|
|`P-08`|[Recover Without Ruining](PUZZLE_P08.md)|Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.|
|`P-09`|[Reconstruct the Departure](PUZZLE_P09.md)|Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.|
|`P-10`|[Flashes and a Signature](PUZZLE_P10.md)|Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.|
|`P-11`|[Protect the Small Light](PUZZLE_P11.md)|Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.|
|`P-12`|[Observe, Isolate, Restore](PUZZLE_P12.md)|Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.|
|`P-13`|[One Integrated Storm Plan](PUZZLE_P13.md)|Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.|
|`P-14`|[Three Waves and a Broken Link](PUZZLE_P14.md)|Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.|
|`P-15`|[Two Teams, One Road](PUZZLE_P15.md)|Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.|
|`P-16`|[The Link and the Living Garden](PUZZLE_P16.md)|Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.|

## Godot UI

|Task|Prompt|Outcome|
|---|---|---|
|`UI01`|[Main menu](UI_01_MAIN_MENU.md)|Implement the Main menu screen/component as a live, accessible GodotControl interface connected to the shared campaign.|
|`UI02`|[New Expedition](UI_02_NEW_EXPEDITION.md)|Implement the New Expedition screen/component as a live, accessible GodotControl interface connected to the shared campaign.|
|`UI03`|[HUD](UI_03_HUD.md)|Implement the HUD screen/component as a live, accessible GodotControl interface connected to the shared campaign.|
|`UI04`|[Objective panel](UI_04_OBJECTIVE_PANEL.md)|Implement the Objective panel screen/component as a live, accessible GodotControl interface connected to the shared campaign.|
|`UI05`|[Dialogue](UI_05_DIALOGUE.md)|Implement the Dialogue screen/component as a live, accessible GodotControl interface connected to the shared campaign.|
|`UI06`|[Interaction](UI_06_INTERACTION.md)|Implement the Interaction screen/component as a live, accessible GodotControl interface connected to the shared campaign.|
|`UI07`|[Expedition journal](UI_07_EXPEDITION_JOURNAL.md)|Implement the Expedition journal screen/component as a live, accessible GodotControl interface connected to the shared campaign.|
|`UI08`|[Discovery log](UI_08_DISCOVERY_LOG.md)|Implement the Discovery log screen/component as a live, accessible GodotControl interface connected to the shared campaign.|
|`UI09`|[Scientific puzzle](UI_09_SCIENTIFIC_PUZZLE.md)|Implement the Scientific puzzle screen/component as a live, accessible GodotControl interface connected to the shared campaign.|
|`UI10`|[Mission Table](UI_10_MISSION_TABLE.md)|Implement the Mission Table screen/component as a live, accessible GodotControl interface connected to the shared campaign.|
|`UI11`|[Rover](UI_11_ROVER.md)|Implement the Rover screen/component as a live, accessible GodotControl interface connected to the shared campaign.|
|`UI12`|[Greenhouse](UI_12_GREENHOUSE.md)|Implement the Greenhouse screen/component as a live, accessible GodotControl interface connected to the shared campaign.|
|`UI13`|[Outcome](UI_13_OUTCOME.md)|Implement the Outcome screen/component as a live, accessible GodotControl interface connected to the shared campaign.|
|`UI14`|[Pause](UI_14_PAUSE.md)|Implement the Pause screen/component as a live, accessible GodotControl interface connected to the shared campaign.|
|`UI15`|[Settings](UI_15_SETTINGS.md)|Implement the Settings screen/component as a live, accessible GodotControl interface connected to the shared campaign.|
|`UI16`|[Credits](UI_16_CREDITS.md)|Implement the Credits screen/component as a live, accessible GodotControl interface connected to the shared campaign.|

## Final cutscene

|Task|Prompt|Outcome|
|---|---|---|
|`CS-01`|[Arrival at Aurora; Ferreira on the Earth screen](CUTSCENE_CS01.md)|Finish/integrate `CS-01` for `EX-CH01-S01` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-02`|[Last light; masts stop; Earth link greys out](CUTSCENE_CS02.md)|Finish/integrate `CS-02` for `EX-CH01-S09` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-03`|[Chamber check, shutter opens, Alo's first flower; N.'s stored message](CUTSCENE_CS03.md)|Finish/integrate `CS-03` for `EX-CH01-S12` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-04`|[The cup trembles; four crew brace; the pressure warning changes](CUTSCENE_CS04.md)|Finish/integrate `CS-04` for `EX-CH02-S12` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-05`|[Suited entry to the 2034 annex: unflowered seedlings only (**no buds**, overriding the old CIN-04 text)](CUTSCENE_CS05.md)|Finish/integrate `CS-05` for `EX-CH03-S07` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-06`|[Forty-two seeds counted; Mei's grief; nobody leaves](CUTSCENE_CS06.md)|Finish/integrate `CS-06` for `EX-CH03-S10` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-07`|[Headlights find a manufactured corner: the vault](CUTSCENE_CS07.md)|Finish/integrate `CS-07` for `EX-CH04-S06` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-08`|[Relief lander on the landing camera; Ferreira at the airlock; the fifth mug](CUTSCENE_CS08.md)|Finish/integrate `CS-08` for `EX-CH05-S01` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-09`|[Ferreira seated level with the crew: "I was the engineer who could not fix the radio."](CUTSCENE_CS09.md)|Finish/integrate `CS-09` for `EX-CH05-S05` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-10`|[Signed page → Noor's portrait → faces; consent line](CUTSCENE_CS10.md)|Finish/integrate `CS-10` for `EX-CH05-S10` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-11`|[Red ring on the filtered camera with the labelled Earth-limb diagram](CUTSCENE_CS11.md)|Finish/integrate `CS-11` for `EX-CH06-S07` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-12`|[Camera feed drops, the guide light stays on; Kai isolates F2 with Rafi on the channel](CUTSCENE_CS12.md)|Finish/integrate `CS-12` for `EX-CH06-S10` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-13`|[Noor's last log in the storm lull; Mei holds the petal near the seed case](CUTSCENE_CS13.md)|Finish/integrate `CS-13` for `EX-CH07-S07` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-14`|[Three in the rover, two at home; the airlock seals](CUTSCENE_CS14.md)|Finish/integrate `CS-14` for `EX-CH08-S01` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-15`|["Hello, Aurora. This is Noor." Cuts between the summit cabin, Aurora and the Dhaka rooftop](CUTSCENE_CS15.md)|Finish/integrate `CS-15` for `EX-CH08-S10` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-16`|[The same road home; five crew at Aurora at 03: 00](CUTSCENE_CS16.md)|Finish/integrate `CS-16` for `EX-CH08-S11` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-17`|[Shutter at first light: descendant garden, cotton alive, petal beside the label; the shared photo](CUTSCENE_CS17.md)|Finish/integrate `CS-17` for `EX-CH08-S12` using current approved anime production, preserving player agency and exact narrative facts.|
|`CS-18`|[Closed MARS drawer still (no new quest)](CUTSCENE_CS18.md)|Finish/integrate `CS-18` for `post-credits` using current approved anime production, preserving player agency and exact narrative facts.|

## Voice production

|Task|Prompt|Outcome|
|---|---|---|
|`VO-AMARA`|[Amara voice/performance group](VOICE_AMARA.md)|Produce/integrate the assigned `Amara` performances from the exact script, reusing already approved recordings and maintaining canonical delivery origin.|
|`VO-ENGINEER`|[Engineer voice/performance group](VOICE_ENGINEER.md)|Produce/integrate the assigned `Engineer` performances from the exact script, reusing already approved recordings and maintaining canonical delivery origin.|
|`VO-FAMILY`|[Family voice/performance group](VOICE_FAMILY.md)|Produce/integrate the assigned `Family` performances from the exact script, reusing already approved recordings and maintaining canonical delivery origin.|
|`VO-FERREIRA`|[Ferreira voice/performance group](VOICE_FERREIRA.md)|Produce/integrate the assigned `Ferreira` performances from the exact script, reusing already approved recordings and maintaining canonical delivery origin.|
|`VO-KAI`|[Kai voice/performance group](VOICE_KAI.md)|Produce/integrate the assigned `Kai` performances from the exact script, reusing already approved recordings and maintaining canonical delivery origin.|
|`VO-MEI`|[Mei voice/performance group](VOICE_MEI.md)|Produce/integrate the assigned `Mei` performances from the exact script, reusing already approved recordings and maintaining canonical delivery origin.|
|`VO-N_ARCHIVE`|[N. voice/performance group](VOICE_N_ARCHIVE.md)|Produce/integrate the assigned `N.` performances from the exact script, reusing already approved recordings and maintaining canonical delivery origin.|
|`VO-NOOR`|[Noor voice/performance group](VOICE_NOOR.md)|Produce/integrate the assigned `Noor` performances from the exact script, reusing already approved recordings and maintaining canonical delivery origin.|
|`VO-RAFI`|[Rafi voice/performance group](VOICE_RAFI.md)|Produce/integrate the assigned `Rafi` performances from the exact script, reusing already approved recordings and maintaining canonical delivery origin.|
|`VO-RAO`|[Rao voice/performance group](VOICE_RAO.md)|Produce/integrate the assigned `Rao` performances from the exact script, reusing already approved recordings and maintaining canonical delivery origin.|

## Music cue

|Task|Prompt|Outcome|
|---|---|---|
|`CUE-01`|[Home Not Yet](MUSIC_CUE01.md)|Produce and integrate this original score cue/stem family with the source emotional function, loop behaviour and owning scene triggers.|
|`CUE-02`|[Small Work](MUSIC_CUE02.md)|Produce and integrate this original score cue/stem family with the source emotional function, loop behaviour and owning scene triggers.|
|`CUE-03`|[Last Light](MUSIC_CUE03.md)|Produce and integrate this original score cue/stem family with the source emotional function, loop behaviour and owning scene triggers.|
|`CUE-04`|[First Flower](MUSIC_CUE04.md)|Produce and integrate this original score cue/stem family with the source emotional function, loop behaviour and owning scene triggers.|
|`CUE-05`|[Unfinished](MUSIC_CUE05.md)|Produce and integrate this original score cue/stem family with the source emotional function, loop behaviour and owning scene triggers.|
|`CUE-06`|[Beyond Home](MUSIC_CUE06.md)|Produce and integrate this original score cue/stem family with the source emotional function, loop behaviour and owning scene triggers.|
|`CUE-07`|[A Name](MUSIC_CUE07.md)|Produce and integrate this original score cue/stem family with the source emotional function, loop behaviour and owning scene triggers.|
|`CUE-08`|[Red Ring](MUSIC_CUE08.md)|Produce and integrate this original score cue/stem family with the source emotional function, loop behaviour and owning scene triggers.|
|`CUE-09`|[All We Learned](MUSIC_CUE09.md)|Produce and integrate this original score cue/stem family with the source emotional function, loop behaviour and owning scene triggers.|
|`CUE-10`|[Known Road](MUSIC_CUE10.md)|Produce and integrate this original score cue/stem family with the source emotional function, loop behaviour and owning scene triggers.|
|`CUE-11`|[Hello Aurora](MUSIC_CUE11.md)|Produce and integrate this original score cue/stem family with the source emotional function, loop behaviour and owning scene triggers.|
|`CUE-12`|[What We Grew](MUSIC_CUE12.md)|Produce and integrate this original score cue/stem family with the source emotional function, loop behaviour and owning scene triggers.|

## Sound effect

|Task|Prompt|Outcome|
|---|---|---|
|`SFX_FAN_NORMAL`|[Station circulation fans (interior bed)](SFX_01.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_FAN_LOWPOWER`|[Fans on reduced power (night / eclipse)](SFX_02.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_GREENHOUSE_FAN`|[Garden chamber fan and grow-lamp hum](SFX_03.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_PUMP_PRESSURE`|[Pressure pump running](SFX_04.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_WATER_TRANSFER`|[Water moving through the wall lines](SFX_05.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_VALVE_DETENT`|[Valve click into position](SFX_06.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_GLOVE_PORT`|[Hands entering glove ports (rubber contact)](SFX_07.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_BRUSH_CONTACT`|[Soft pollination brush contact](SFX_08.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_SEED_TICK`|[Dry seeds dropping into a tray](SFX_09.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_SHUTTER_OPEN`|[Chamber viewing shutter sliding open](SFX_10.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_DOOR_LATCH`|[Interior door latch](SFX_11.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_HATCH_SEAL`|[Shelter hatch sealing](SFX_12.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_AIRLOCK_CYCLE`|[Airlock pressure cycle (equal ising)](SFX_13.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_SUIT_BREATH`|[Breathing inside a suit helmet](SFX_14.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_RADIO_LOCAL_IN`|[Local radio channel opening (clean)](SFX_15.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_RADIO_EARTH_IN`|[Earth link channel opening (with latency texture)](SFX_16.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_RADIO_EARTH_LOST`|[Earth link fading to silence](SFX_17.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_RECORDER_AGED`|[Old recorder playback texture (archive)](SFX_18.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_ALERT_PARTICLE`|[Particle-event instrument alarm (not a projectile sound)](SFX_19.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_ALERT_PRESSURE`|[Pressure warning tone](SFX_20.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_ALERT_STRUCTURAL`|[Structural shaking alarm](SFX_21.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_QUAKE_CONTACT`|[Moon quake felt through the floor (structure-borne only)](SFX_22.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_CUP_RATTLE`|[Mug rattling on the table](SFX_23.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_CLAMP_SEAT`|[Repair clamp seating on a pipe](SFX_24.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_CONNECTOR`|[Electrical connector mating](SFX_25.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_BREAKER_RESET`|[Feeder isolate / reset clunk](SFX_26.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_BATTERY_SWAP`|[Battery pack removal and insertion](SFX_27.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_CONTROLLER_POWERUP`|[Relay controller powering up](SFX_28.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_ROVER_CABIN`|[Press uri sed rover cabin hum](SFX_29.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_ROVER_CHASSIS`|[Rover wheels felt through the chassis (no airborne sound)](SFX_30.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_SCANNER_BEEP`|[Ice scanner reading](SFX_31.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_CAMERA_SHUTTER`|[Photo capture](SFX_32.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_UI_CONFIRM`|[Interface confirm](SFX_33.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_UI_SOFT_ERROR`|[Gentle error (never a humiliating buzzer)](SFX_34.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|
|`SFX_UI_SHIFT_COMMIT`|[Committing a shift / plan](SFX_35.md)|Produce and integrate this specific effect/ambience with correct physical listening context, variations and text-equivalent event.|

## Audio integration

|Task|Prompt|Outcome|
|---|---|---|
|`AUDIO-MIX`|[Full-campaign voice, music, SFX and caption integration](AUDIO_FULL_CAMPAIGN_MIX.md)|Integrate all assigned voice groups,12 score cues,35 SFX and cutscene audio into a coherent complete campaign mix.|

## Effects / independent QA / release

|Task|Prompt|Outcome|
|---|---|---|
|`VFX01`|[Lunar exterior effects and restrained hazards](VFX_01_LUNAR_ENVIRONMENT.md)|Create grounded lunar visual feedback for footsteps, wheels, moon quake/impact and hardware events.|
|`VFX02`|[Plant stress, growth-light and habitat state feedback](VFX_02_PLANT_AND_HABITAT.md)|Build lifecycle/stress/environment feedback that accurately reflects biology and shared resources.|
|`VFX03`|[Eclipse, camera and instrument visualisation](VFX_03_ECLIPSE_AND_INSTRUMENTS.md)|Implement qualified filtered camera and data visuals for light/sky/storm/radio evidence.|
|`QA01`|[Independent canon and learning audit](QA_01_CANON_AND_LEARNING.md)|Audit the implemented whole campaign against the final story, knowledge/roster/seed/travelled gers and meaningful junior learning.|
|`QA02`|[Numeric, resource, upgrades and deterministic regression](QA_02_NUMERIC_AND_UPGRADES.md)|Independently verify P01..16, the pure preview/commit model and all reachable upgrade profiles.|
|`QA03`|[Full route, interactions, saves and recovery](QA_03_RUNTIME_AND_SAVES.md)|Validate functional completion from new expedition through credits under real interactions and persistence.|
|`QA04`|[Independent anime, animation and interaction visual review](QA_04_VISUAL_CONTACTS.md)|Review the actual GPU/moving results for cast, props, plants, world and cutscenes.|
|`QA05`|[Accessible controls, reading, modes and learner UX](QA_05_ACCESSIBILITY_AND_UX.md)|Verify whole-story access with keyboard/controller, mute, large-text, reduced motion and timer assistance.|
|`QA06`|[Performance, import, export and cross-host reproducibility](QA_06_PERFORMANCE_AND_PORTABILITY.md)|Verify runtime performance and asset/media availability on agreed targets and fresh checkouts.|
|`REL01`|[Portable game export, versioning and reproducible package](RELEASE_01_EXPORT_AND_PACKAGE.md)|Produce a tested release candidate of the implemented game with complete content and correct runtime assets.|
|`REL02`|[Credits, science provenance, AI log and submission evidence](RELEASE_02_CREDITS_AND_EVIDENCE.md)|Prepare accurate credits/provenance and review able evidence for the actual delivered game.|

## Scientific evidence artifact

|Task|Prompt|Outcome|
|---|---|---|
|`SRC-MOON`|[Moon facts](SCIENCE_SRC_MOON.md)|Produce the offline source card and any genuinely required evidence illustration/processed artifact for this primary source, with the exact supported-claim boundary below.|
|`SRC-POLAR`|[Shackleton's illuminated rim and shadowed interior](SCIENCE_SRC_POLAR.md)|Produce the offline source card and any genuinely required evidence illustration/processed artifact for this primary source, with the exact supported-claim boundary below.|
|`SRC-LIFE-SUPPORT`|[Life support subsystems](SCIENCE_SRC_LIFE_SUPPORT.md)|Produce the offline source card and any genuinely required evidence illustration/processed artifact for this primary source, with the exact supported-claim boundary below.|
|`SRC-PLANTS`|[Fast Plants frequently asked questions](SCIENCE_SRC_PLANTS.md)|Produce the offline source card and any genuinely required evidence illustration/processed artifact for this primary source, with the exact supported-claim boundary below.|
|`SRC-POLLINATION`|[Pollination and cross-pollination](SCIENCE_SRC_POLLINATION.md)|Produce the offline source card and any genuinely required evidence illustration/processed artifact for this primary source, with the exact supported-claim boundary below.|
|`SRC-QUAKES`|[Moon quakes and faults near the lunar south pole](SCIENCE_SRC_QUAKES.md)|Produce the offline source card and any genuinely required evidence illustration/processed artifact for this primary source, with the exact supported-claim boundary below.|
|`SRC-ICE`|[LCROSS mission and polar water evidence](SCIENCE_SRC_ICE.md)|Produce the offline source card and any genuinely required evidence illustration/processed artifact for this primary source, with the exact supported-claim boundary below.|
|`SRC-IMPACTS`|[Lunar impact monitoring](SCIENCE_SRC_IMPACTS.md)|Produce the offline source card and any genuinely required evidence illustration/processed artifact for this primary source, with the exact supported-claim boundary below.|
|`SRC-ECLIPSE`|[Eclipses and the Moon](SCIENCE_SRC_ECLIPSE.md)|Produce the offline source card and any genuinely required evidence illustration/processed artifact for this primary source, with the exact supported-claim boundary below.|
|`SRC-ECLIPSE-DATE`|[Lunar eclipse catalog 2001–2100](SCIENCE_SRC_ECLIPSE_DATE.md)|Produce the offline source card and any genuinely required evidence illustration/processed artifact for this primary source, with the exact supported-claim boundary below.|
|`SRC-STORM2012`|[The big CME that missed Earth](SCIENCE_SRC_STORM2012.md)|Produce the offline source card and any genuinely required evidence illustration/processed artifact for this primary source, with the exact supported-claim boundary below.|
|`SRC-STORM2017`|[September 2017 solar storm at Mars](SCIENCE_SRC_STORM2017.md)|Produce the offline source card and any genuinely required evidence illustration/processed artifact for this primary source, with the exact supported-claim boundary below.|
|`SRC-SHIELDING`|[Materials and protection from space radiation](SCIENCE_SRC_SHIELDING.md)|Produce the offline source card and any genuinely required evidence illustration/processed artifact for this primary source, with the exact supported-claim boundary below.|
|`SRC-RELAY`|[Moonlight and south-polar communications](SCIENCE_SRC_RELAY.md)|Produce the offline source card and any genuinely required evidence illustration/processed artifact for this primary source, with the exact supported-claim boundary below.|
|`SRC-COTTON2019`|[Chang'e-4 cotton germination: experiment-team report](SCIENCE_SRC_COTTON2019.md)|Produce the offline source card and any genuinely required evidence illustration/processed artifact for this primary source, with the exact supported-claim boundary below.|

## Upgrade pair

|Task|Prompt|Outcome|
|---|---|---|
|`UP-1`|[After Chapter 1 upgrade pair](UPGRADE_AFTER_CH01.md)|Implement this earned mutually exclusive upgrade pair at its correct acquisition boundary, including visible hardware/UI state and the shared numeric modifier.|
|`UP-2`|[After Chapter 2 upgrade pair](UPGRADE_AFTER_CH02.md)|Implement this earned mutually exclusive upgrade pair at its correct acquisition boundary, including visible hardware/UI state and the shared numeric modifier.|
|`UP-3`|[After Chapter 3 upgrade pair](UPGRADE_AFTER_CH03.md)|Implement this earned mutually exclusive upgrade pair at its correct acquisition boundary, including visible hardware/UI state and the shared numeric modifier.|
|`UP-4`|[After Chapter 4 upgrade pair](UPGRADE_AFTER_CH04.md)|Implement this earned mutually exclusive upgrade pair at its correct acquisition boundary, including visible hardware/UI state and the shared numeric modifier.|
|`UP-5`|[After Chapter 5 upgrade pair](UPGRADE_AFTER_CH05.md)|Implement this earned mutually exclusive upgrade pair at its correct acquisition boundary, including visible hardware/UI state and the shared numeric modifier.|
|`UP-6`|[After Chapter 6 upgrade pair](UPGRADE_AFTER_CH06.md)|Implement this earned mutually exclusive upgrade pair at its correct acquisition boundary, including visible hardware/UI state and the shared numeric modifier.|
|`UP-7`|[After Chapter 7 upgrade pair](UPGRADE_AFTER_CH07.md)|Implement this earned mutually exclusive upgrade pair at its correct acquisition boundary, including visible hardware/UI state and the shared numeric modifier.|

## Outcome and recovery

|Task|Prompt|Outcome|
|---|---|---|
|`END-GOLDEN_BLOOM`|[Golden Bloom](ENDING_GOLDEN_BLOOM.md)|Implement the Golden Bloom outcome as an accessible, causally supported chapter closure connected to real state and correct retry/advance semantics.|
|`END-BLOOM`|[Bloom](ENDING_BLOOM.md)|Implement the Bloom outcome as an accessible, causally supported chapter closure connected to real state and correct retry/advance semantics.|
|`END-ALO_LOST`|[Alo lost](ENDING_ALO_LOST.md)|Implement the Alo lost outcome as an accessible, causally supported chapter closure connected to real state and correct retry/advance semantics.|
|`END-MISSION_STOPPED`|[Mission stopped](ENDING_MISSION_STOPPED.md)|Implement the Mission stopped outcome as an accessible, causally supported chapter closure connected to real state and correct retry/advance semantics.|

## Animation content

|Task|Prompt|Outcome|
|---|---|---|
|`AN-CARE_SCIENCE`|[Care and science contact animation](ANIMATION_CARE_SCIENCE.md)|Finish the specific animation family for current approved characters and actual scene props: Plant, pollinate, inspect, scan, count seeds, sleeve a petal and operate sealed glove ports.|
|`AN-REPAIR_VEHICLE`|[Repair, shelter, airlock and vehicle contact animation](ANIMATION_REPAIR_VEHICLE.md)|Finish the specific animation family for current approved characters and actual scene props: Valve turn, clamp, isolate/verify, connector/controller/battery replacement, crate placement, tether, boarding and seated vehicle work.|
|`AN-REACTIONS_CINEMATICS`|[Companion and narrative performance animation](ANIMATION_REACTIONS_CINEMATICS.md)|Finish the specific animation family for current approved characters and actual scene props: Offer lamp, place mug, roll-call acknowledgement, curiosity, quiet grief, supported fear, shared photo and restrained reunion.|

## Scene-to-mission ownership

|Chapter|Mission|Final scenes|Target minutes|
|---|---|---|---|
|1: Night One|[EX-M0101](MISSION_EX_M0101.md)|EX-CH01-S01, EX-CH01-S02, EX-CH01-S03|18|
|1: Night One|[EX-M0102](MISSION_EX_M0102.md)|EX-CH01-S04, EX-CH01-S05, EX-CH01-S06|18|
|1: Night One|[EX-M0103](MISSION_EX_M0103.md)|EX-CH01-S07, EX-CH01-S08, EX-CH01-S09|18|
|1: Night One|[EX-M0104](MISSION_EX_M0104.md)|EX-CH01-S10, EX-CH01-S11, EX-CH01-S12|21|
|2: Be the Bee|[EX-M0201](MISSION_EX_M0201.md)|EX-CH02-S01, EX-CH02-S02, EX-CH02-S03|18|
|2: Be the Bee|[EX-M0202](MISSION_EX_M0202.md)|EX-CH02-S04, EX-CH02-S05, EX-CH02-S06|18|
|2: Be the Bee|[EX-M0203](MISSION_EX_M0203.md)|EX-CH02-S07, EX-CH02-S08, EX-CH02-S09|18|
|2: Be the Bee|[EX-M0204](MISSION_EX_M0204.md)|EX-CH02-S10, EX-CH02-S11, EX-CH02-S12|21|
|3: Moon quake|[EX-M0301](MISSION_EX_M0301.md)|EX-CH03-S01, EX-CH03-S02, EX-CH03-S03|20|
|3: Moon quake|[EX-M0302](MISSION_EX_M0302.md)|EX-CH03-S04, EX-CH03-S05, EX-CH03-S06|21|
|3: Moon quake|[EX-M0303](MISSION_EX_M0303.md)|EX-CH03-S07, EX-CH03-S08, EX-CH03-S09|21|
|3: Moon quake|[EX-M0304](MISSION_EX_M0304.md)|EX-CH03-S10, EX-CH03-S11, EX-CH03-S12|23|
|4: Into the Cold Trap|[EX-M0401](MISSION_EX_M0401.md)|EX-CH04-S01, EX-CH04-S02, EX-CH04-S03|22|
|4: Into the Cold Trap|[EX-M0402](MISSION_EX_M0402.md)|EX-CH04-S04, EX-CH04-S05, EX-CH04-S06|22|
|4: Into the Cold Trap|[EX-M0403](MISSION_EX_M0403.md)|EX-CH04-S07, EX-CH04-S08, EX-CH04-S09|22|
|4: Into the Cold Trap|[EX-M0404](MISSION_EX_M0404.md)|EX-CH04-S10, EX-CH04-S11, EX-CH04-S12|24|
|5: Shooting Stars|[EX-M0501](MISSION_EX_M0501.md)|EX-CH05-S01, EX-CH05-S02, EX-CH05-S03|20|
|5: Shooting Stars|[EX-M0502](MISSION_EX_M0502.md)|EX-CH05-S04, EX-CH05-S05, EX-CH05-S06|20|
|5: Shooting Stars|[EX-M0503](MISSION_EX_M0503.md)|EX-CH05-S07, EX-CH05-S08, EX-CH05-S09|25|
|5: Shooting Stars|[EX-M0504](MISSION_EX_M0504.md)|EX-CH05-S10, EX-CH05-S11, EX-CH05-S12|20|
|6: The Red Ring|[EX-M0601](MISSION_EX_M0601.md)|EX-CH06-S01, EX-CH06-S02, EX-CH06-S03|20|
|6: The Red Ring|[EX-M0602](MISSION_EX_M0602.md)|EX-CH06-S04, EX-CH06-S05, EX-CH06-S06|25|
|6: The Red Ring|[EX-M0603](MISSION_EX_M0603.md)|EX-CH06-S07, EX-CH06-S08, EX-CH06-S09|20|
|6: The Red Ring|[EX-M0604](MISSION_EX_M0604.md)|EX-CH06-S10, EX-CH06-S11, EX-CH06-S12|20|
|7: The Great Storm|[EX-M0701](MISSION_EX_M0701.md)|EX-CH07-S01, EX-CH07-S02, EX-CH07-S03|25|
|7: The Great Storm|[EX-M0702](MISSION_EX_M0702.md)|EX-CH07-S04, EX-CH07-S05, EX-CH07-S06|25|
|7: The Great Storm|[EX-M0703](MISSION_EX_M0703.md)|EX-CH07-S07, EX-CH07-S08, EX-CH07-S09|30|
|7: The Great Storm|[EX-M0704](MISSION_EX_M0704.md)|EX-CH07-S10, EX-CH07-S11, EX-CH07-S12|25|
|8: The Lighthouse|[EX-M0801](MISSION_EX_M0801.md)|EX-CH08-S01, EX-CH08-S02, EX-CH08-S03|30|
|8: The Lighthouse|[EX-M0802](MISSION_EX_M0802.md)|EX-CH08-S04, EX-CH08-S05, EX-CH08-S06|30|
|8: The Lighthouse|[EX-M0803](MISSION_EX_M0803.md)|EX-CH08-S07, EX-CH08-S08, EX-CH08-S09|30|
|8: The Lighthouse|[EX-M0804](MISSION_EX_M0804.md)|EX-CH08-S10, EX-CH08-S11, EX-CH08-S12|30|

## Prompt-package validation

Validation checks structure, coverage, local references and snapshot faithfulness. It does not certify that the game implementation tasks were executed. Read the resulting`98_PROMPT_PACKAGE_VALIDATION.md`for actual counts and limits.
