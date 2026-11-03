extends RefCounted
class_name CampaignRoomContract

## Stable, data-only contracts for the first playable habitat route.
## Geometry and interaction state are built by CampaignRoom; this file owns
## names, adjacency-facing IDs, canonical dimensions and approved asset reuse.

const ROOM_IDS := ["LOC-01", "LOC-02", "LOC-03", "LOC-04", "LOC-06"]

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
		"boundary_ids": ["door_commons_service", "door_commons_garden", "door_commons_safe", "airlock_exterior"],
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
}

static func room_ids() -> Array:
	return ROOM_IDS.duplicate()

static func room(room_id: String) -> Dictionary:
	if not _ROOMS.has(room_id):
		return {}
	return (_ROOMS[room_id] as Dictionary).duplicate(true)

static func room_for_scene(scene_id: String) -> String:
	return String(_SCENE_ROOMS.get(scene_id, "LOC-01"))

static func scene_room_map() -> Dictionary:
	return _SCENE_ROOMS.duplicate(true)

static func all_focus_targets(room_id: String) -> Array:
	var definition := room(room_id)
	return definition.get("focus_targets", []).duplicate(true)

static func anchors(room_id: String) -> Dictionary:
	var definition := room(room_id)
	return definition.get("anchors", {}).duplicate(true)

static func all_asset_paths(room_id: String) -> Array:
	var definition := room(room_id)
	return definition.get("asset_paths", []).duplicate(true)

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
