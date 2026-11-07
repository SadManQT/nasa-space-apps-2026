extends RefCounted
class_name CampaignRoomContract

## Stable, data-only contracts for the first playable habitat route.
## Geometry and interaction state are built by CampaignRoom; this file owns
## names, adjacency-facing IDs, canonical dimensions and approved asset reuse.

const ROOM_IDS := ["LOC-01", "LOC-02", "LOC-03", "LOC-04", "LOC-05", "LOC-06", "LOC-07", "LOC-08", "LOC-09", "LOC-10", "LOC-11", "LOC-12"]

const _ROOMS := {
	"LOC-01": {
		"room_id": "LOC-01",
		"name": "Commons",
		"canonical_name": "Aurora commons / Mission Table",
		"bounds_m": [22.0, 12.0],
		"pressure": "pressurised",
		"asset_ids": ["PR_MissionTable", "PR_BatteryJar", "PR_SeedPacket", "PR_Mug"],
		"asset_paths": [
			"res://assets/props/PR_MissionTable/PR_MissionTable.glb",
			"res://assets/props/PR_BatteryJar/PR_BatteryJar.glb",
			"res://assets/props/PR_SeedPacket/PR_SeedPacket.glb",
			"res://assets/props/PR_Mug/PR_Mug.glb",
		],
		"boundary_ids": ["door_commons_service", "door_commons_garden", "door_commons_safe", "door_commons_airlock"],
		"focus_targets": [
			{"target_id": "commons_mission_table", "label": "Mission Table", "verb": "Inspect", "position": [0.0, 0.9, 0.0]},
			{"target_id": "commons_earth_screen", "label": "Earth screen", "verb": "Inspect", "position": [0.0, 1.6, -5.0]},
			{"target_id": "commons_charter", "label": "Charter and emergency card", "verb": "Inspect", "position": [-4.0, 1.0, -2.0]},
		],
		"anchors": {
			"commons_kai": [-3.6, 0.0, 1.8],
			"commons_amara": [-1.2, 0.0, 1.8],
			"commons_mei": [1.2, 0.0, 1.8],
			"commons_rafi": [3.6, 0.0, 1.8],
			"commons_player": [0.0, 0.0, 3.7],
			"commons_viewpoint": [0.0, 1.5, 4.5],
		},
	},
	"LOC-02": {
		"room_id": "LOC-02",
		"name": "Service Rooms",
		"canonical_name": "Power and atmosphere service rooms",
		"bounds_m": [12.0, 6.0],
		"pressure": "pressurised",
		"asset_ids": ["PR_PowerPanel", "PR_BatteryJar", "PR_OxygenUnit", "PR_ControlConsole", "PR_WaterValve", "PR_HandLight"],
		"asset_paths": [
			"res://assets/props/PR_PowerPanel/PR_PowerPanel.glb",
			"res://assets/props/PR_BatteryJar/PR_BatteryJar.glb",
			"res://assets/props/PR_OxygenUnit/PR_OxygenUnit.glb",
			"res://assets/props/PR_ControlConsole/PR_ControlConsole.glb",
			"res://assets/props/PR_WaterValve/PR_WaterValve.glb",
			"res://assets/props/PR_HandLight/PR_HandLight.glb",
		],
		"boundary_ids": ["door_commons_service", "door_service_garden", "door_service_safe"],
		"focus_targets": [
			{"target_id": "service_power_panel", "label": "Power panel", "verb": "Inspect", "position": [-3.5, 1.0, -1.5]},
			{"target_id": "service_air_console", "label": "Air console", "verb": "Inspect", "position": [0.0, 1.0, -1.5]},
			{"target_id": "service_garden_valve", "label": "Garden spur valve", "verb": "Inspect", "position": [3.5, 0.8, -1.5]},
			{"target_id": "service_hand_light", "label": "Hand-light locker", "verb": "Inspect", "position": [3.5, 1.0, 1.5]},
		],
		"anchors": {
			"service_kai": [-3.2, 0.0, 1.6],
			"service_amara": [0.0, 0.0, 1.6],
			"service_rafi": [3.2, 0.0, 1.6],
			"service_player": [0.0, 0.0, 2.3],
		},
	},
	"LOC-03": {
		"room_id": "LOC-03",
		"name": "Garden",
		"canonical_name": "Garden room and external Alo chamber",
		"bounds_m": [12.0, 8.0],
		"pressure": "pressurised",
		"asset_ids": ["PR_GrowthChamber", "PR_Glovebox", "PL_CropRack", "PL_Alo_Bud", "PL_Tara_Bloom"],
		"asset_paths": [
			"res://assets/props/PR_GrowthChamber/PR_GrowthChamber.glb",
			"res://assets/props/PR_Glovebox/PR_Glovebox.glb",
			"res://assets/plants/PL_CropRack/PL_CropRack.glb",
			"res://assets/plants/PL_Alo_Bud/PL_Alo_Bud.glb",
			"res://assets/plants/PL_Tara_Bloom/PL_Tara_Bloom.glb",
		],
		"boundary_ids": ["door_commons_garden", "door_service_garden", "garden_viewing_shutter"],
		"focus_targets": [
			{"target_id": "garden_alo_glove_port", "label": "Alo sealed glove port", "verb": "Inspect", "position": [-3.2, 1.0, -1.5]},
			{"target_id": "garden_tara_bay", "label": "Tara reference bay", "verb": "Inspect", "position": [0.0, 1.0, -1.5]},
			{"target_id": "garden_probe", "label": "Moisture probe and references", "verb": "Inspect", "position": [3.2, 1.0, -1.5]},
			{"target_id": "garden_shutter", "label": "Viewing shutter", "verb": "OpenDoor", "position": [0.0, 1.4, -3.4]},
		],
		"anchors": {
			"garden_mei": [-2.8, 0.0, 2.0],
			"garden_amara": [2.8, 0.0, 2.0],
			"garden_kai": [-4.0, 0.0, 2.8],
			"garden_rafi": [4.0, 0.0, 2.8],
			"garden_player": [0.0, 0.0, 3.1],
			"garden_chamber": [0.0, 0.0, -2.0],
		},
	},
	"LOC-04": {
		"room_id": "LOC-04",
		"name": "Safe Room",
		"canonical_name": "Safe Room",
		"bounds_m": [8.0, 6.0],
		"pressure": "pressurised",
		"asset_ids": ["PR_CrewSeat", "PR_WaterWallPanel", "PR_CrewBunk", "PR_SupplyBundles", "PR_HatchDoor"],
		"asset_paths": [
			"res://assets/props/PR_CrewSeat/PR_CrewSeat.glb",
			"res://assets/props/PR_WaterWallPanel/PR_WaterWallPanel.glb",
			"res://assets/props/PR_CrewBunk/PR_CrewBunk.glb",
			"res://assets/props/PR_SupplyBundles/PR_SupplyBundles.glb",
			"res://assets/props/PR_HatchDoor/PR_HatchDoor.glb",
		],
		"boundary_ids": ["door_commons_safe", "door_service_safe", "safe_room_exposure_lock"],
		"focus_targets": [
			{"target_id": "safe_roll_call_board", "label": "Roll-call board", "verb": "Inspect", "position": [-2.5, 1.2, -2.0]},
			{"target_id": "safe_water_wall", "label": "Water wall and return valve", "verb": "Inspect", "position": [0.0, 1.0, -2.0]},
			{"target_id": "safe_response_controls", "label": "Response controls", "verb": "Inspect", "position": [2.5, 1.0, -2.0]},
			{"target_id": "safe_hatch", "label": "Safe Room hatch", "verb": "OpenDoor", "position": [0.0, 1.2, 2.3]},
		],
		"anchors": {
			"safe_kai": [-2.5, 0.0, 0.8],
			"safe_amara": [-0.8, 0.0, 0.8],
			"safe_mei": [0.8, 0.0, 0.8],
			"safe_rafi": [2.5, 0.0, 0.8],
			"safe_ferreira": [0.0, 0.0, -0.7],
			"safe_player": [0.0, 0.0, 2.0],
		},
	},
	"LOC-05": {
		"room_id": "LOC-05",
		"name": "Airlock",
		"canonical_name": "Airlock and sealed transfer vestibule",
		"bounds_m": [8.0, 4.0],
		"pressure": "pressurised",
		"asset_ids": ["EN_Airlock_GlovePort", "EN_Airlock_PassThrough", "EN_Airlock_InterlockPanel", "EN_Airlock_SuitLocker", "EN_Airlock_Bench"],
		"asset_paths": [
			"res://assets/environment/EN_Airlock/EN_Airlock_GlovePort_LOD0.glb",
			"res://assets/environment/EN_Airlock/EN_Airlock_PassThrough_LOD0.glb",
			"res://assets/environment/EN_Airlock/EN_Airlock_InterlockPanel_LOD0.glb",
			"res://assets/environment/EN_Airlock/EN_Airlock_SuitLocker_LOD0.glb",
			"res://assets/environment/EN_Airlock/EN_Airlock_Bench_LOD0.glb",
		],
		# The inner door to the Commons (east wall) and the outer hatch to the surface (west; the M3-2A interlock). The
		# module is turned half a revolution (LOC-05.json shell_yaw_deg), so its garden wall is the north wall.
		"boundary_ids": ["door_commons_airlock", "airlock_exterior"],
		"focus_targets": [
			{"target_id": "transfer_glove_ports", "label": "Alo glove ports", "verb": "Inspect", "position": [2.0, 1.2, -1.9]},
			{"target_id": "transfer_carrier", "label": "Sealed carrier pass-through", "verb": "Inspect", "position": [1.0, 1.22, -1.6]},
			{"target_id": "transfer_microscope", "label": "Pollen microscope", "verb": "Inspect", "position": [0.0, 1.05, -1.75]},
		],
		"anchors": {"transfer_mei": [2.6, 0.0, -0.4], "transfer_amara": [1.4, 0.0, -0.2], "transfer_rafi": [-0.3, 0.0, 0.6], "transfer_kai": [3.3, 0.0, 0.6], "transfer_player": [2.0, 0.0, 0.4]},
	},
	"LOC-06": {
		"room_id": "LOC-06",
		"name": "Exterior",
		"canonical_name": "Aurora mast courtyard",
		"bounds_m": [120.0, 120.0],
		"pressure": "vacuum",
		"asset_ids": ["EN_ExteriorModule", "EN_SolarMast", "PR_Dosimeter", "PR_Helmet"],
		"asset_paths": [
			"res://assets/environment/EN_ExteriorModule/EN_ExteriorModule.glb",
			"res://assets/environment/EN_SolarMast/EN_SolarMast.glb",
			"res://assets/props/PR_Dosimeter/PR_Dosimeter.glb",
			"res://assets/props/PR_Helmet/PR_Helmet.glb",
		],
		"boundary_ids": ["airlock_exterior"],
		"focus_targets": [
			{"target_id": "exterior_mast_status", "label": "Mast status panel", "verb": "Inspect", "position": [-8.0, 1.0, -4.0]},
			{"target_id": "exterior_chamber_label", "label": "Chamber service label", "verb": "Inspect", "position": [0.0, 1.0, -5.0]},
			{"target_id": "exterior_return_marker", "label": "Return route marker", "verb": "Inspect", "position": [8.0, 0.5, 0.0]},
		],
		"anchors": {
			"exterior_kai": [-2.0, 0.0, 2.0],
			"exterior_rafi": [2.0, 0.0, 2.0],
			"exterior_player": [0.0, 0.0, 5.0],
			"exterior_airlock": [0.0, 0.0, 8.0],
		},
	},
	"LOC-07": {
		"room_id": "LOC-07",
		"name": "Isolated Annex",
		"canonical_name": "Expedition Zero isolated service annex and its warm-side access bay",
		"bounds_m": [8.0, 6.0],
		"pressure": "pressurised",
		"asset_ids": ["EN_ZeroAnnex_FloorHatch", "EN_ZeroAnnex_SupportStation", "EN_ZeroAnnex_TrayBench", "EN_ZeroAnnex_ChartArchive", "PL_ZeroSeedlingTray", "PR_AnnexDrum"],
		"asset_paths": [
			"res://assets/plants/PL_ZeroSeedlingTray/PL_ZeroSeedlingTray.glb",
			"res://assets/props/PR_AnnexDrum/PR_AnnexDrum.glb",
		],
		# M3-3R: the warm-side bay connects to the service rooms through its own pressure door; the N.R. floor hatch is
		# the boundary between the warm bay and the cold annex 3 m below (doc 09 LOC-07).
		"boundary_ids": ["door_service_annex", "annex_hatch"],
		"focus_targets": [
			{"target_id": "annex_utility_feed", "label": "Annex utility isolation", "verb": "Use", "position": [-2.75, 0.4, -0.75]},
			{"target_id": "annex_zero_gauge", "label": "Zero differential gauge", "verb": "Inspect", "position": [-2.6, 1.0, 2.4]},
			{"target_id": "annex_hatch_view", "label": "N.R. hatch viewing port", "verb": "Inspect", "position": [-2.0, 0.4, -0.17]},
		],
		"anchors": {"annex_mei": [-0.6, 0.0, 1.4], "annex_amara": [-3.2, 0.0, 1.4], "annex_rafi": [-0.8, 0.0, -1.9], "annex_kai": [-3.3, 0.0, -1.6], "annex_player": [1.6, 0.0, 0.8]},
	},
	"LOC-08": {
		"room_id": "LOC-08",
		"name": "Rover Garage",
		"canonical_name": "Aurora rover garage: pressurised ready room and vacuum rover bay",
		"bounds_m": [12.0, 9.0],
		# The ready room (the deck people walk unsuited) is pressurised; the rover bay and the EVA porch are vacuum and
		# entered only in suits through the rover's suitports (decisions 1 and 4; LOC-08.json "zones").
		"pressure": "pressurised",
		"asset_ids": ["EN_Garage_DockingPort", "EN_Garage_CargoLock", "EN_Garage_HandoverConsole", "VH_Rover"],
		"asset_paths": [
			"res://assets/environment/EN_Garage/EN_Garage_DockingPort_LOD0.glb",
			"res://assets/environment/EN_Garage/EN_Garage_CargoLock_LOD0.glb",
			"res://assets/environment/EN_Garage/EN_Garage_HandoverConsole_LOD0.glb",
			"res://assets/vehicles/VH_Rover/VH_Rover.glb",
		],
		# The inner door to the pressurised kit corridor to the Commons (decision 2), the dock hatch to the docked rover's
		# cabin, and the rover door from the vacuum bay to the apron and the marked path to the courtyard (LOC-06).
		"boundary_ids": ["door_commons_garage", "garage_dock_hatch", "rover_bay_door"],
		"focus_targets": [
			{"target_id": "rover_seal", "label": "Suit seals and dock seal", "verb": "Inspect", "position": [-5.0, 1.84, -1.53]},
			{"target_id": "rover_loadout", "label": "Cargo rack and supply ledger", "verb": "Inspect", "position": [5.17, 1.32, -3.9]},
			{"target_id": "base_handover", "label": "Handover console", "verb": "Inspect", "position": [2.5, 1.42, -4.2]},
		],
		"anchors": {"rover_rafi": [2.5, 0.0, -2.0], "rover_kai": [1.6, 0.0, -2.1], "rover_player": [-1.8, 0.0, -2.9]},
	},
	"LOC-09": {
		"room_id": "LOC-09",
		"name": "Surveyed Ridge",
		"canonical_name": "Cold-trap surveyed ridge road",
		"bounds_m": [30.0, 30.0],
		"pressure": "vacuum",
		# M3-106 (decision 8): three 100 m segments at the computed beacon corners B1, B2, B3 (EX-CH04-S04) and the last
		# bend before the basin (EX-CH04-S05's reference and sample station), built from the M3-4A EN_ColdTrap pieces
		# (LOC-09.json, "site_kit"); placements in exterior_terrain.json, one per segment.
		"asset_ids": ["EN_ColdTrap_BeaconMast", "EN_ColdTrap_ReturnMarker", "EN_ColdTrap_SlopeSign", "EN_ColdTrap_ReferencePlate", "EN_ColdTrap_SampleStake", "PR_IceScanner", "VH_Rover"],
		"asset_paths": [
			"res://assets/environment/EN_ColdTrap/EN_ColdTrap_BeaconMast_LOD0.glb",
			"res://assets/environment/EN_ColdTrap/EN_ColdTrap_ReturnMarker_LOD0.glb",
			"res://assets/environment/EN_ColdTrap/EN_ColdTrap_SlopeSign_LOD0.glb",
			"res://assets/environment/EN_ColdTrap/EN_ColdTrap_ReferencePlate_LOD0.glb",
			"res://assets/environment/EN_ColdTrap/EN_ColdTrap_SampleStake_LOD0.glb",
			"res://assets/props/PR_IceScanner/PR_IceScanner.glb",
			"res://assets/vehicles/VH_Rover/VH_Rover.glb",
		],
		# The road from the garage's rover door (LOC-08) and the walk down to the vault shelf (LOC-10): route
		# transitions in the rover or on foot, never doors standing on the open ridge.
		"boundary_ids": ["rover_bay_door", "ridge_route_boundary"],
		"focus_targets": [
			{"target_id": "ridge_beacon_pad", "label": "Beacon mast", "verb": "Use", "position": [-5.2, 1.0, 0.0]},
			{"target_id": "ice_scanner", "label": "Calibrated ice scanner", "verb": "Use", "position": [0.0, 0.6, -3.0]},
		],
		"anchors": {"ridge_rafi": [-3.0, 0.0, 2.5], "ridge_kai": [-1.0, 0.0, 4.0], "ridge_player": [-2.0, 0.0, 3.0]},
	},
	"LOC-10": {
		"room_id": "LOC-10",
		"name": "Cold-trap Vault",
		"canonical_name": "Cold-trap vault shelf",
		"bounds_m": [24.0, 24.0],
		"pressure": "vacuum",
		# M3-106: the 20 x 15 m shelf in permanent shadow (decision 10) with vault V12 as deposited, the 2034 marker, two
		# tether anchors, the recovery carrier and VH_Rover 15 m back with its lamps (LOC-10.json, "site_kit").
		"asset_ids": ["PR_VaultCase", "EN_ColdTrap_SurveyMarker2034", "EN_ColdTrap_TetherAnchor", "PR_VaultCarrier", "PR_VaultProbe", "VH_Rover"],
		"asset_paths": [
			"res://assets/props/PR_VaultCase/PR_VaultCase.glb",
			"res://assets/environment/EN_ColdTrap/EN_ColdTrap_SurveyMarker2034_LOD0.glb",
			"res://assets/environment/EN_ColdTrap/EN_ColdTrap_TetherAnchor_LOD0.glb",
			"res://assets/props/PR_VaultCarrier/PR_VaultCarrier.glb",
			"res://assets/props/PR_VaultProbe/PR_VaultProbe.glb",
			"res://assets/vehicles/VH_Rover/VH_Rover.glb",
		],
		"boundary_ids": ["ridge_route_boundary", "vault_recovery_boundary"],
		"focus_targets": [
			{"target_id": "vault_probe", "label": "Vault outer probe socket", "verb": "Use", "position": [0.3, 0.2, -0.85]},
			{"target_id": "vault_sleeve", "label": "Insulated sleeve and cradle", "verb": "Use", "position": [-1.0, 0.45, 0.5]},
			{"target_id": "vault_case", "label": "Closed biological case", "verb": "Inspect", "position": [0.3, 0.3, -0.5]},
		],
		"anchors": {"vault_rafi": [2.6, 0.0, -1.9], "vault_kai": [-1.9, 0.0, -0.2], "vault_player": [0.8, 0.0, 1.8]},
	},
	"LOC-11": {
		"room_id": "LOC-11",
		"name": "Relay Route",
		"canonical_name": "Surveyed relay route and repeater sectors",
		"bounds_m": [60.0, 20.0],
		"pressure": "vacuum",
		"asset_ids": ["VH_Rover", "PR_SurveyBeacon", "PR_RelayController", "PR_UplinkFeedthrough"],
		"asset_paths": [
			"res://assets/vehicles/VH_Rover/VH_Rover.glb",
			"res://assets/props/PR_SurveyBeacon/PR_SurveyBeacon.glb",
			"res://assets/props/PR_RelayController/PR_RelayController.glb",
			"res://assets/props/PR_UplinkFeedthrough/PR_UplinkFeedthrough.glb",
		],
		# M3-8R: the road continues out of the marker-two sector at both ends (LOC-11.json places the markers).
		"boundary_ids": ["relay_route_boundary"],
		"focus_targets": [
			{"target_id": "relay_route_console", "label": "Relay route console", "verb": "Inspect", "position": [-5.0, 1.0, -3.0]},
			{"target_id": "repeater_chain", "label": "Three repeater buoys", "verb": "Use", "position": [0.0, 0.8, -3.0]},
			{"target_id": "relay_controller", "label": "Relay controller housing", "verb": "Use", "position": [5.0, 1.0, -3.0]},
		],
		"anchors": {"relay_kai": [-2.0, 0.0, 2.0], "relay_rafi": [2.0, 0.0, 2.0], "relay_player": [0.0, 0.0, 4.0]},
	},
	"LOC-12": {
		"room_id": "LOC-12",
		"name": "Malapert Relay",
		"canonical_name": "Malapert relay summit work platform",
		"bounds_m": [32.0, 22.0],
		# M3-8R: the 30 x 20 m relay platform is open vacuum on the summit (doc 09 LOC-12); the pressurised space there
		# is the rover cabin, which staging marks with "aboard".
		"pressure": "vacuum",
		"asset_ids": ["PR_RelayController", "PR_UplinkFeedthrough", "PR_HandLight"],
		"asset_paths": [
			"res://assets/props/PR_RelayController/PR_RelayController.glb",
			"res://assets/props/PR_UplinkFeedthrough/PR_UplinkFeedthrough.glb",
			"res://assets/props/PR_HandLight/PR_HandLight.glb",
		],
		"boundary_ids": ["relay_route_boundary", "relay_service_boundary"],
		"focus_targets": [
			{"target_id": "relay_isolator", "label": "Relay power isolator", "verb": "Use", "position": [-4.0, 1.0, -2.0]},
			{"target_id": "relay_local_bearing", "label": "Local bearing control", "verb": "Use", "position": [0.0, 1.0, -2.0]},
			{"target_id": "relay_earth_bearing", "label": "Earth bearing control", "verb": "Use", "position": [4.0, 1.0, -2.0]},
		],
		"anchors": {"relay_service_kai": [-3.0, 0.0, 2.0], "relay_service_rafi": [3.0, 0.0, 2.0], "relay_service_player": [0.0, 0.0, 4.0]},
	},
}

const _SCENE_ROOMS := {
	"EX-CH01-S01": "LOC-01",
	"EX-CH01-S02": "LOC-04",
	"EX-CH01-S03": "LOC-01",
	"EX-CH01-S04": "LOC-03",
	"EX-CH01-S05": "LOC-02",
	"EX-CH01-S06": "LOC-01",
	"EX-CH01-S07": "LOC-02",
	"EX-CH01-S08": "LOC-04",
	"EX-CH01-S09": "LOC-01",
	"EX-CH01-S10": "LOC-04",
	"EX-CH01-S11": "LOC-03",
	"EX-CH01-S12": "LOC-03",
	"EX-CH02-S01": "LOC-03", "EX-CH02-S02": "LOC-03", "EX-CH02-S03": "LOC-05",
	"EX-CH02-S04": "LOC-05", "EX-CH02-S05": "LOC-05", "EX-CH02-S06": "LOC-03",
	"EX-CH02-S07": "LOC-01", "EX-CH02-S08": "LOC-02", "EX-CH02-S09": "LOC-02",
	"EX-CH02-S10": "LOC-02", "EX-CH02-S11": "LOC-01", "EX-CH02-S12": "LOC-01",
	# Chapter 3 (M3-3R), from each scene's location in STORY_FULL.md, the CHAPTER_03 scene scripts (SC-0301..0306),
	# doc 09 and scene_rosters.json: the atmosphere service corridor, taps, preview board, garden spur and console in the
	# service rooms (S01-S05); the annex access bay with the N.R. hatch and the cold annex 3 m below it (S06-S08: camera
	# port, suited entry, map provenance at the warm-side evidence table); the garden maturity, drying and harvest
	# benches and planting rack (S09-S11); Tara's indoor reference bay, the lineage board and the October rack (S12).
	"EX-CH03-S01": "LOC-02", "EX-CH03-S02": "LOC-02", "EX-CH03-S03": "LOC-02",
	"EX-CH03-S04": "LOC-02", "EX-CH03-S05": "LOC-02", "EX-CH03-S06": "LOC-07",
	"EX-CH03-S07": "LOC-07", "EX-CH03-S08": "LOC-07", "EX-CH03-S09": "LOC-03",
	"EX-CH03-S10": "LOC-03", "EX-CH03-S11": "LOC-03", "EX-CH03-S12": "LOC-03",
	# Chapter 6 (M3-6R), from each scene's location in STORY_FULL.md and the CHAPTER_06 scene scripts: the power
	# room holds the locker, plan, board, test panel and F2 (S01-S05, S10) and the debrief at the board (S11, SC-0605);
	# the eclipse desk and its filtered monitor stand by the Mission Table (S06-S09, SC-0603/0604); S12 is the garden.
	"EX-CH06-S01": "LOC-02", "EX-CH06-S02": "LOC-02", "EX-CH06-S03": "LOC-02",
	"EX-CH06-S04": "LOC-02", "EX-CH06-S05": "LOC-02", "EX-CH06-S06": "LOC-01",
	"EX-CH06-S07": "LOC-01", "EX-CH06-S08": "LOC-01", "EX-CH06-S09": "LOC-01",
	"EX-CH06-S10": "LOC-02", "EX-CH06-S11": "LOC-02", "EX-CH06-S12": "LOC-03",
	# Chapter 7 (M3-7R), from STORY_FULL.md, the CHAPTER_07 scene scripts (SC-0701..0706) and scene_rosters.json: the
	# warning at the Mission Table (S01); the Safe Room for preparation, roll call and the six storm steps (S02-S08); the
	# Commons network diagnostic and care-planning desk (S09-S10); the fabrication bench and route simulator in the
	# service rooms (S11); the departure boards and rover loadout in the garage (S12; moved from the Commons in M3-105).
	"EX-CH07-S01": "LOC-01", "EX-CH07-S02": "LOC-04", "EX-CH07-S03": "LOC-04",
	"EX-CH07-S04": "LOC-04", "EX-CH07-S05": "LOC-04", "EX-CH07-S06": "LOC-04",
	"EX-CH07-S07": "LOC-04", "EX-CH07-S08": "LOC-04", "EX-CH07-S09": "LOC-01",
	"EX-CH07-S10": "LOC-01", "EX-CH07-S11": "LOC-02", "EX-CH07-S12": "LOC-08",
	# Chapter 4 (M3-4R), from STORY_FULL.md and the CHAPTER_04 scene scripts: the descendant rack in the garden (S01); the
	# rover garage's ready room for the departure checks and the route cards (S02-S03, M3-105) and for the return through
	# the dock and the dry cargo lock (S09); the three beacon segments of the ridge road (S04-S05) and the vault shelf
	# (S06-S08) on the LOLA terrain (M3-106); the dry quarantine glovebox in the garden (S10); the Earth console (S11) and
	# the mission table with the fifth mug (S12) in the Commons. CH07-S12's two destination boards are the garage's
	# departure boards (decision 7), so that scene moved here from the Commons.
	"EX-CH04-S01": "LOC-03", "EX-CH04-S02": "LOC-08", "EX-CH04-S03": "LOC-08",
	"EX-CH04-S04": "LOC-09", "EX-CH04-S05": "LOC-09", "EX-CH04-S06": "LOC-10",
	"EX-CH04-S07": "LOC-10", "EX-CH04-S08": "LOC-10", "EX-CH04-S09": "LOC-08",
	"EX-CH04-S10": "LOC-03", "EX-CH04-S11": "LOC-01", "EX-CH04-S12": "LOC-01",
	# Chapter 8 (M3-8R), from STORY_FULL.md, the CHAPTER_08 scene scripts (SC-0801..0806), doc 24 2.8-2.9 and the
	# approved M3-8A sets: the departure and the arrival in the rover garage (S01, S11; staged with EN_Garage by
	# M3-105); the relay road's marker-two sector with the crew aboard the pressurised rover (S02-S03) and the EVA
	# battery swap at its pad (S04); the garden home loop (S05); Aurora's console for the summit arrival packet (S06);
	# the Malapert summit platform for the suited repair, both legs and ALO42 (S07-S09); the Commons table for the
	# three-place call, with Noor on the Earth screen (S10); the garden at first light (S12).
	"EX-CH08-S01": "LOC-08", "EX-CH08-S02": "LOC-11", "EX-CH08-S03": "LOC-11",
	"EX-CH08-S04": "LOC-11", "EX-CH08-S05": "LOC-03", "EX-CH08-S06": "LOC-01",
	"EX-CH08-S07": "LOC-12", "EX-CH08-S08": "LOC-12", "EX-CH08-S09": "LOC-12",
	"EX-CH08-S10": "LOC-01", "EX-CH08-S11": "LOC-08", "EX-CH08-S12": "LOC-03",
}

## Returns every stable location ID in the campaign.
static func room_ids() -> Array:
	return ROOM_IDS.duplicate()

## Resolves the location contract using the existing authored layout as authority.
static func room(room_id: String) -> Dictionary:
	if not _ROOMS.has(room_id):
		return {}
	var result := (_ROOMS[room_id] as Dictionary).duplicate(true)
	var authored := layout(room_id)
	for key in ["bounds_m", "focus_targets", "anchors"]:
		if authored.has(key):
			result[key] = authored[key].duplicate(true)
	if authored.get("assembly") in ["habitat_kit", "site_kit", "exterior_kit"]:
		result["asset_paths"] = []
		result["asset_ids"] = []
		for prop in authored.props:
			if prop.path not in result.asset_paths:
				result.asset_paths.append(prop.path)
			result.asset_ids.append(prop.id)
	return result

## Loads the single authored layout for this location, or an empty fallback.
static func layout(room_id: String) -> Dictionary:
	var path := "res://resources/campaign/rooms/" + room_id + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

## Resolves the physical scene location without changing story progression.
static func room_for_scene(scene_id: String) -> String:
	if _SCENE_ROOMS.has(scene_id):
		return String(_SCENE_ROOMS[scene_id])
	return _extended_room_for_scene(scene_id)

static func _extended_room_for_scene(scene_id: String) -> String:
	var parts := scene_id.split("-")
	if parts.size() != 3:
		return "LOC-01"
	var chapter := int(String(parts[1]).trim_prefix("CH"))
	var order := int(String(parts[2]).trim_prefix("S"))
	match chapter:
		2:
			return ["LOC-03", "LOC-03", "LOC-05", "LOC-05", "LOC-05", "LOC-03", "LOC-01", "LOC-02", "LOC-02", "LOC-02", "LOC-01", "LOC-01"][order - 1]
		3:
			return ["LOC-02", "LOC-02", "LOC-02", "LOC-02", "LOC-02", "LOC-07", "LOC-07", "LOC-07", "LOC-03", "LOC-03", "LOC-03", "LOC-03"][order - 1]
		4:
			return ["LOC-03", "LOC-08", "LOC-08", "LOC-09", "LOC-09", "LOC-10", "LOC-10", "LOC-10", "LOC-08", "LOC-03", "LOC-01", "LOC-01"][order - 1]
		5:
			return ["LOC-08", "LOC-01", "LOC-01", "LOC-01", "LOC-01", "LOC-01", "LOC-01", "LOC-02", "LOC-01", "LOC-01", "LOC-01", "LOC-03"][order - 1]
		7:
			return ["LOC-01", "LOC-04", "LOC-04", "LOC-04", "LOC-04", "LOC-04", "LOC-04", "LOC-04", "LOC-01", "LOC-01", "LOC-02", "LOC-01"][order - 1]
		8:
			return ["LOC-08", "LOC-08", "LOC-11", "LOC-11", "LOC-03", "LOC-08", "LOC-12", "LOC-12", "LOC-12", "LOC-11", "LOC-08", "LOC-03"][order - 1]
	return "LOC-01"

## Returns the authored scene-to-room map as an independent copy.
static func scene_room_map() -> Dictionary:
	return _SCENE_ROOMS.duplicate(true)

## Returns the interaction targets consumed by the world dispatcher.
static func all_focus_targets(room_id: String) -> Array:
	var definition := room(room_id)
	return definition.get("focus_targets", []).duplicate(true)

## Returns the crew/player staging anchors for this room.
static func anchors(room_id: String) -> Dictionary:
	var definition := room(room_id)
	return definition.get("anchors", {}).duplicate(true)

## Returns unique approved GLBs needed by the room loading service.
static func all_asset_paths(room_id: String) -> Array:
	var definition := room(room_id)
	return definition.get("asset_paths", []).duplicate(true)

## Checks the mandatory room contract fields before building geometry.
static func validate(room_id: String) -> Dictionary:
	var definition := room(room_id)
	var errors: Array[String] = []
	if definition.is_empty():
		errors.append("unknown room contract: " + room_id)
	else:
		for required in ["room_id", "name", "bounds_m", "pressure", "boundary_ids", "focus_targets", "anchors"]:
			if not definition.has(required):
				errors.append(room_id + " is missing " + required)
		if definition.get("bounds_m", []).size() != 2:
			errors.append(room_id + " must declare width and depth")
	return {"valid": errors.is_empty(), "errors": errors}

# ------------------------------------------------------------------------------------------- exterior terrain
# M1-82: each playable exterior's placement on the real LOLA terrain (rooms/exterior_terrain.json) for the terrain
# provider (Atik's TerrainStream, M1-36), and the dated Earth in its sky. The flat greybox rooms stay as they are.

const TERRAIN_PATH := "res://resources/campaign/rooms/exterior_terrain.json"
const Heightfield = preload("res://assets/environment/terrain/lola/terrain_heightfield.gd")
## Earth seen from the Moon at the mean distance: 2 atan(6,371 km / 384,400 km) (NSSDCA fact sheets); 1.80 deg at
## apogee to 2.07 deg at perigee. The bundled Horizons rows carry no range, so the mean is used.
const EARTH_ANGULAR_DIAMETER_DEG := 1.899
## The Sun's mean angular diameter (0.533 deg); Earth overlaps it when the centres are closer than the radii sum.
const SUN_ANGULAR_DIAMETER_DEG := 0.533
static var _terrain: Dictionary = {}

## An exterior's terrain placement: region_id, origin_m (the room origin in the region's site frame; put the
## TerrainStream at -origin_m), omit_staging_floor, ephemeris_site / horizon_site, and the derived room-local anchors,
## focus_targets, focus_approaches, props, fixtures and doors on the ground, ground_y_range_m, and the site-frame
## exclusions for TerrainStream.configure. {} for a room without a placement; "pending" says why one is not ready.
## M3-106: a room played in segments (LOC-09: the beacon corners "B1", "B2", "B3" of EX-CH04-S04) keeps one placement
## per segment under "segments" (region, origin, yaw_deg, ephemeris site and the derived numbers); segment returns it
## over the room's own placement (which stays the last bend, EX-CH04-S05), or {} for an unknown segment.
static func terrain(room_id: String, segment: String = "") -> Dictionary:
	if _terrain.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(TERRAIN_PATH))
		_terrain = parsed if parsed is Dictionary else {"rooms": {}}
	var place := (_terrain.get("rooms", {}).get(room_id, {}) as Dictionary).duplicate(true)
	if segment.is_empty():
		return place
	var segments: Dictionary = place.get("segments", {})
	if not segments.has(segment):
		return {}
	var result: Dictionary = segments[segment].duplicate(true)
	result["segment"] = segment
	result["room_placement"] = String(place.get("placement", ""))
	return result

## The segment ids a room is played in ([] for a one-place room).
static func terrain_segments(room_id: String) -> Array:
	return terrain(room_id).get("segments", {}).keys()

## The dated Earth for an exterior in one scene, from its bundled JPL Horizons row (lola/sun_positions.json
## scene_lighting, M1-34). {"presented": true, "direction", "sun_direction" (unit vectors in the room / site frame),
## "angular_diameter_deg", "earth_az_deg", "earth_el_deg", "utc", "site", "sun_earth_elongation_deg",
## "illuminated_fraction", "source"} only when the room stands at the row's site with a computed terrain horizon and
## the row says Earth clears it; an eclipse (Earth over the Sun) is canon only through the filtered camera. Otherwise
## {"presented": false, "reason"}: never a generic Earth.
static func earth(room_id: String, scene_id: String, segment: String = "") -> Dictionary:
	var place := terrain(room_id, segment)
	var row := Heightfield.scene_lighting(scene_id, segment)
	# M3-8R: a scene without its own row may name the row of another scene whose dated time lies inside its story
	# window (exterior_terrain.json "sky_rows", with the reason), e.g. EX-CH08-S07 (00:00-00:45) uses EX-CH08-S06 (00:00).
	var alias := String(place.get("sky_rows", {}).get(scene_id, ""))
	if row.is_empty() and not alias.is_empty():
		row = Heightfield.scene_lighting(alias, segment)
	var result := {"presented": false, "room_id": room_id, "scene_id": scene_id}
	# a segment's own row carries the terrain horizon where that segment stands (make_terrain.py horizon_from)
	var horizon_here := String(row.get("site", "")) == String(place.get("horizon_site", "")) or (not segment.is_empty() and row.has("horizon_from"))
	if place.is_empty():
		result.reason = "The room has no terrain placement."
	elif row.is_empty():
		result.reason = "No bundled Horizons row for this scene."
	elif String(row.site) != String(place.get("ephemeris_site", "")):
		result.reason = "The scene's row belongs to another site (%s)." % row.site
	elif not horizon_here:
		result.reason = "No terrain horizon was computed where this room stands."
	elif not bool(row.get("earth_above_terrain", false)):
		result.reason = "Earth is below the local terrain horizon."
	if result.has("reason"):
		return result
	var site: Dictionary = Heightfield.sun_table().sites[String(row.site)]
	# a turned segment room (yaw_deg) sees the sky in its own frame
	var into_room := Basis(Vector3.UP, -deg_to_rad(float(place.get("yaw_deg", 0.0))))
	var to_earth := into_room * Heightfield.sun_direction_at(float(site.x_m), float(site.y_m), float(row.earth_az_deg), float(row.earth_el_deg))
	var to_sun := into_room * Heightfield.sun_direction_at(float(site.x_m), float(site.y_m), float(row.sun_az_deg), float(row.sun_el_deg))
	var elongation := rad_to_deg(to_earth.angle_to(to_sun))
	if elongation < (EARTH_ANGULAR_DIAMETER_DEG + SUN_ANGULAR_DIAMETER_DEG) * 0.5:
		result.reason = "Earth is in front of the Sun (an eclipse): shown only through the filtered camera."
		return result
	result.merge({
		"presented": true, "site": String(row.site), "utc": String(row.utc),
		"earth_az_deg": float(row.earth_az_deg), "earth_el_deg": float(row.earth_el_deg),
		"angular_diameter_deg": EARTH_ANGULAR_DIAMETER_DEG,
		"direction": [to_earth.x, to_earth.y, to_earth.z], "sun_direction": [to_sun.x, to_sun.y, to_sun.z],
		"sun_earth_elongation_deg": elongation, "illuminated_fraction": (1.0 - cos(deg_to_rad(elongation))) * 0.5,
		"source": "JPL Horizons DE441, %s %s UTC (sun_positions.json scene_lighting %s; terrain horizon from LOLA)" % [row.site, row.utc, String(row.scene)],
	}, true)
	return result

# ------------------------------------------------------------------------------------------- chapter staging
# A room JSON's optional "staging" array holds dated layers (doc 09 revisit rules: props accumulate between
# chapters; only mission-specific controls change state). A layer, and any item inside it, is active from its
# "from" scene to its "until" scene (inclusive, either optional); "by_scene" (a scene id or an inclusive
# "FROM..UNTIL" range) overrides fields for those scenes; "choice" / "unless" gate an echo layer on a recorded
# story_log option (doc 24 §5.2). The base layout stays the Chapter 1 room; staging only adds and hides.

const _STAGING_LISTS := ["props", "fixtures", "obstacles", "focus_targets", "signs", "local_lights", "eclipse_props", "chapter7_props", "prints", "models", "hide", "hide_signs", "kit_screens"]
const _STAGING_MAPS := ["anchors", "focus_labels", "lighting", "stations", "carried", "review_views", "care_round", "kit_parts", "kit_texts", "kit_attach", "outfits", "garage", "piece_states", "aboard"]

## Story order of a canon scene id (chapter * 100 + scene number), or -1 for anything that is not one.
static func scene_order(scene_id: String) -> int:
	var parts := scene_id.split("-")
	if parts.size() != 3 or parts[0] != "EX" or not parts[1].begins_with("CH") or not parts[2].begins_with("S"):
		return -1
	return int(parts[1].substr(2)) * 100 + int(parts[2].substr(1))

## True when scene_id lies inside an item's dated window ("from"/"until", inclusive, either optional).
static func in_window(item: Dictionary, scene_id: String) -> bool:
	var at := scene_order(scene_id)
	if at < 0:
		return false
	if item.has("from") and at < scene_order(String(item.from)):
		return false
	if item.has("until") and at > scene_order(String(item.until)):
		return false
	return true

## The chapter staging a room shows in one scene: every active layer's additions (props, fixtures, obstacles,
## focus targets, signs, lights, M3-6A eclipse props, M3-7A Chapter 7 props, prints), what it hides from the base layout, merged anchors,
## focus relabels, per-scene lighting, the stations each scene action uses, and objects a cast member carries.
## choices is story_log.choices (choice_id -> {"option_id", ...}) and moments story_log.moments (e.g. "CH01-MUGS-NAMED");
## they only gate echo layers ("choice" / "unless" / "moment" / "unless_moment").
static func staging(room_id: String, scene_id: String, choices: Dictionary = {}, moments: Array = [], segment: String = "") -> Dictionary:
	return staging_for(layout(room_id), scene_id, choices, moments, segment)

## staging() for a layout the caller already holds (a built room keeps its own), so the JSON is not read again.
## A layer or item with "segment" shows only on that segment of a room played in segments (M3-106: the slope sign's value
## at each beacon corner); one without it shows on every segment.
static func staging_for(room_layout: Dictionary, scene_id: String, choices: Dictionary = {}, moments: Array = [], segment: String = "") -> Dictionary:
	var result := {"layers": [], "walk_probe": []}
	for key in _STAGING_LISTS:
		result[key] = []
	for key in _STAGING_MAPS:
		result[key] = {}
	for raw_layer in room_layout.get("staging", []):
		if not raw_layer is Dictionary or not _choice_met(raw_layer, choices) or (raw_layer.has("moment") and not moments.has(raw_layer.moment)) or moments.has(raw_layer.get("unless_moment", "")):
			continue
		if raw_layer.has("segment") and String(raw_layer.segment) != segment:
			continue
		var layer := _resolve(raw_layer, scene_id)
		if layer.is_empty():
			continue
		result.layers.append(String(layer.get("id", "")))
		for key in _STAGING_LISTS:
			for item in layer.get(key, []):
				if item is Dictionary:
					var one := _resolve(item, scene_id)
					if not one.is_empty() and (not one.has("segment") or String(one.segment) == segment):
						result[key].append(one)
				else:
					result[key].append(item)
		for key in _STAGING_MAPS:
			var values: Dictionary = layer.get(key, {})
			for name in values:
				result[key][name] = values[name].duplicate(true) if values[name] is Dictionary or values[name] is Array else values[name]
		if layer.has("walk_probe"):
			result.walk_probe = layer.walk_probe.duplicate(true)
	return result

## The location as it stands in one scene: the base layout with hidden items removed and the active staging
## added (the shape the M1-06 checks read: props, fixtures, obstacles, focus_targets, anchors, signs, walk_probe).
## The applied staging itself is under "stage".
static func staged_layout(room_id: String, scene_id: String, choices: Dictionary = {}, moments: Array = [], segment: String = "") -> Dictionary:
	return staged_layout_for(layout(room_id), scene_id, choices, moments, segment)

## staged_layout() for a layout the caller already holds.
static func staged_layout_for(base: Dictionary, scene_id: String, choices: Dictionary = {}, moments: Array = [], segment: String = "") -> Dictionary:
	if base.is_empty():
		return {}
	var stage := staging_for(base, scene_id, choices, moments, segment)
	var result := base.duplicate(true)
	result.erase("staging")
	for key in ["props", "fixtures", "obstacles", "local_lights"]:
		var kept: Array = []
		for item in base.get(key, []):
			if String(item.get("id", "")) not in stage.hide:
				kept.append(item.duplicate(true))
		result[key] = kept + stage[key]
	var targets: Array = []
	for target in base.get("focus_targets", []):
		var copy: Dictionary = target.duplicate(true)
		if stage.focus_labels.has(String(copy.target_id)):
			copy.label = String(stage.focus_labels[copy.target_id])
		targets.append(copy)
	result.focus_targets = targets + stage.focus_targets
	var signs: Array = []
	for sign in base.get("signs", []):
		if String(sign.text) not in stage.hide_signs:
			signs.append(sign.duplicate(true))
	result.signs = signs + stage.signs
	result.anchors = base.get("anchors", {}).duplicate(true)
	result.anchors.merge(stage.anchors, true)
	result.review_views = base.get("review_views", {}).duplicate(true)
	result.review_views.merge(stage.review_views, true)
	if not stage.walk_probe.is_empty():
		result.walk_probe = stage.walk_probe.duplicate(true)
	result["stage"] = stage
	return result

## Crew and player anchors for one scene (base anchors with the active staging's overrides).
static func staged_anchors(room_id: String, scene_id: String, choices: Dictionary = {}, moments: Array = []) -> Dictionary:
	var result := anchors(room_id)
	result.merge(staging(room_id, scene_id, choices, moments).anchors, true)
	return result

## The room station (a focus target id) that a scene's action happens at, from the active staging's "stations",
## or "" when the room data names none (callers keep their own fallback).
static func station_focus(scene_id: String, action: String) -> String:
	return String(staging(room_for_scene(scene_id), scene_id).stations.get(action, ""))

## M1-84: where a dated Care Round (doc 24 §7.2) visits each real plant, from the garden's staging ("care_round"):
## plant id (ALO-01, TARA-01) -> {"focus_target", "plant_anchor", "stand", "face", "photo_view", "reach"}. The care
## always happens in the garden (LOC-03), also in EX-CH01-S05, whose corridor scene plays in the service rooms.
## {} outside a care window.
static func care_round(scene_id: String) -> Dictionary:
	return staging("LOC-03", scene_id).care_round

static func _resolve(item: Dictionary, scene_id: String) -> Dictionary:
	if not in_window(item, scene_id):
		return {}
	var result := item.duplicate(true)
	result.erase("by_scene")
	var overrides: Dictionary = item.get("by_scene", {})
	for key in overrides:
		var span := String(key).split("..")
		if in_window({"from": span[0], "until": span[span.size() - 1]}, scene_id):
			for field in overrides[key]:
				var value = overrides[key][field]
				result[field] = value.duplicate(true) if value is Dictionary or value is Array else value
	return result

static func _choice_met(layer: Dictionary, choices: Dictionary) -> bool:
	for gate in ["choice", "unless"]:
		if not layer.has(gate):
			continue
		var spec: Dictionary = layer[gate]
		var recorded = choices.get(String(spec.get("choice_id", "")), {})
		var picked := String(recorded.get("option_id", "")) if recorded is Dictionary else String(recorded)
		if (picked == String(spec.get("option_id", ""))) != (gate == "choice"):
			return false
	return true
