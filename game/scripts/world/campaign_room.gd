extends Node3D
class_name CampaignRoom

const Presentation = preload("res://scripts/world/room_presentation.gd")
const RoomContract = preload("res://scripts/world/room_contract.gd")
const Habitat = preload("res://scripts/world/habitat_room_builder.gd")
const KitDoor = preload("res://scripts/world/habitat_pressure_door.gd")
const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
const DoorScript = preload("res://scripts/navigation/campaign_door.gd")
const AssetGeometryScript = preload("res://scripts/asset_geometry.gd")
const ToonMaterialsScript = preload("res://scripts/toon_materials.gd")
const Staging = preload("res://scripts/world/room_staging.gd")
## PR_CrewSeat: cushion runs from 0.2 m behind to 0.5 m in front of the pivot at 0.44 m high.
const SEAT_SIT_OFFSET_M := 0.3
const PlantServiceScript = preload("res://scripts/biology/plant_service.gd")
## Stage node inside PL_Alo_Sprout / PL_Tara_Sprout for each PlantService.seedling_form, and its words.
const SEEDLING_NODES := {"seed": "Stage_Seed", "cotyledon": "Stage_Cotyledon", "true_leaf": "Stage_TrueLeaf"}
const SEEDLING_WORDS := {"seed": "SOWN SEED", "cotyledon": "SEED LEAVES", "true_leaf": "TRUE LEAVES"}

@export var room_id := "LOC-01"
@export var load_approved_assets := true
@export var build_navigation := true

var visual_root: Node3D
var collision_root: Node3D
var focus_root: Node3D
var pressure_root: Node3D
var door_root: Node3D
var anchor_root: Node3D
var navigation_root: Node3D
var _built := false
var _layout: Dictionary = {}
var _selection_frames: Dictionary = {}
var _focus_id := ""
var _scene_context := ""
const PLANT_STAGE_MODELS_PATH := "res://assets/plants/plant_stage_models.json"
static var _plant_stage_models: Dictionary = {}
var _choices: Dictionary = {}
var _stage: Dictionary = {}
var _stage_signature := ""

func _ready() -> void:
	build_room()

## Builds this room once, preserving stable roots and interaction IDs.
func build_room() -> Dictionary:
	if _built:
		return {"accepted": true, "room_id": room_id, "duplicate": true}
	var contract := RoomContract.room(room_id)
	if contract.is_empty():
		push_error("CampaignRoom has no contract for " + room_id)
		return {"accepted": false, "reason": "Unknown room contract."}
	_layout = RoomContract.layout(room_id)
	set_meta("room_name", contract.get("name", "AURORA"))
	visual_root = _node_root("VisualRoot")
	collision_root = _node_root("CollisionRoot")
	focus_root = _node_root("FocusTargets")
	pressure_root = _node_root("PressureBoundaries")
	door_root = _node_root("Doors")
	anchor_root = _node_root("CompanionAnchors")
	navigation_root = _node_root("Navigation")
	var stamp := LoadTrace.begin()
	if _layout.get("assembly") == "habitat_kit":
		Habitat.build(self, _layout)
	else:
		_build_floor_and_walls(contract)
	LoadTrace.end("room_shell:" + room_id, stamp)
	stamp = LoadTrace.begin()
	Presentation.build(self, _layout, contract.get("pressure") == "vacuum")
	_build_doors(contract)
	_build_focus_targets(contract)
	_build_pressure_markers(contract)
	_build_anchors(contract)
	if _layout.get("assembly") == "habitat_kit":
		for obstacle in _layout.obstacles:
			Habitat.collider(collision_root, String(obstacle.id), Presentation.vector(obstacle.position), Presentation.vector(obstacle.size))
	LoadTrace.end("room_fixtures_doors:" + room_id, stamp)
	stamp = LoadTrace.begin()
	if build_navigation:
		if _layout.get("assembly") == "habitat_kit":
			Habitat.navigation(navigation_root, _layout)
		else:
			_build_navigation(contract)
	LoadTrace.end("room_navigation:" + room_id, stamp)
	if load_approved_assets:
		_load_approved_assets(contract)
	_build_selection_frames(contract)
	if contract.get("pressure") == "vacuum":
		_style_vacuum(visual_root)
		_style_vacuum(collision_root)
	set_meta("room_id", room_id)
	set_meta("visual_root", "VisualRoot")
	set_meta("collision_root", "CollisionRoot")
	set_meta("focus_root", "FocusTargets")
	set_meta("pressure_root", "PressureBoundaries")
	set_meta("door_root", "Doors")
	set_meta("anchor_root", "CompanionAnchors")
	_built = true
	return {
		"accepted": true,
		"room_id": room_id,
		"pressure": String(contract.get("pressure", "pressurised")),
		"focus_target_count": focus_root.get_child_count(),
		"door_count": door_root.get_child_count(),
		"anchor_count": anchor_root.get_child_count(),
	}

## Returns the authored focus anchors for the existing interaction dispatcher.
func focus_targets() -> Array:
	var result: Array = []
	if focus_root == null:
		return result
	for child in focus_root.get_children():
		result.append({
			"target_id": String(child.get_meta("target_id", child.name)),
			"label": String(child.get_meta("focus_label", child.name)),
			"verb": String(child.get_meta("verb", "Inspect")),
			"position": [child.position.x, child.position.y, child.position.z],
		})
	return result

## Returns the stable scene roots consumed by campaign staging.
func named_roots() -> Dictionary:
	return {
		"visual_root": visual_root,
		"collision_root": collision_root,
		"focus_root": focus_root,
		"pressure_root": pressure_root,
		"door_root": door_root,
		"anchor_root": anchor_root,
		"navigation_root": navigation_root,
	}

## Mirrors the authoritative WorldRoute pressure-boundary state.
func set_door_open(boundary_id: String, is_open: bool) -> bool:
	if door_root == null:
		return false
	for node in door_root.get_children():
		if String(node.get_meta("boundary_id", "")) == boundary_id and node is CampaignDoor:
			(node as CampaignDoor).set_open(is_open)
			if boundary_id == "garden_viewing_shutter" and _layout.get("assembly") == "habitat_kit":
				var shutter := visual_root.get_node_or_null("shutter") as Node3D
				if shutter != null:
					shutter.visible = not is_open
			return true
	return false

## Shows each garden plant's model for its dated stage at its sealed chamber anchor. The biology service decides
## the stage and, before the bud, the seedling form; this only picks the matching model and stage node.
func apply_plant_state(plants: Array) -> void:
	if room_id != "LOC-03" or visual_root == null:
		return
	var biology := PlantServiceScript.new()
	for individual in ["ALO-01", "TARA-01"]:
		var stage := "seed"
		var form := "seed"
		for plant in plants:
			if plant is Dictionary and String(plant.get("individual_id", "")) == individual:
				stage = String(plant.get("stage", "seed"))
				form = biology.seedling_form(plant)
		var prefix := "PL_Alo_" if individual == "ALO-01" else "PL_Tara_"
		for model in visual_root.get_children():
			if String(model.name).begins_with(prefix):
				model.hide()
		var asset := ""
		if SEEDLING_NODES.has(form):
			asset = prefix + "Sprout"
		elif individual == "ALO-01":
			asset = {"bud": "PL_Alo_Bud", "bloom": "PL_Alo_Bloom", "pollinated": "PL_Alo_Bloom", "pod_bearing": "PL_Alo_Pods", "mature_pods": "PL_Alo_Pods", "mature_dry": "PL_Alo_Pods"}.get(stage, "")
		elif stage in ["bloom", "pollinated"]:
			asset = "PL_Tara_Bloom"
		asset = plant_stage_model(individual, stage, asset)
		var focus_id := "garden_alo_glove_port" if individual == "ALO-01" else "garden_tara_bay"
		var focus := focus_root.get_node_or_null("Focus_" + focus_id) as Node3D
		if focus != null:
			var words := stage.to_upper() + (" · " + String(SEEDLING_WORDS[form]) if SEEDLING_WORDS.has(form) else "")
			(focus.get_child(0) as Label3D).text = String(focus.get_meta("focus_label")) + " · " + words
		# shortcut: label Tara's bud until an approved Tara bud model exists.
		if asset.is_empty() or not load_approved_assets:
			continue
		var model := visual_root.get_node_or_null(asset) as Node3D
		if model == null:
			model = AssetGeometryScript.load_glb("res://assets/plants/%s/%s.glb" % [asset, asset])
			if model == null:
				continue
			model.name = asset
			model.scale = Vector3.ONE * (1.0 if _layout.get("assembly") == "habitat_kit" else 0.85)
			visual_root.add_child(model)
			if _layout.get("assembly") != "habitat_kit":
				ToonMaterialsScript.apply_to_tree(model, false, true)
		if _layout.get("plant_positions", {}).has(individual):
			model.position = Presentation.vector(_layout.plant_positions[individual])
		elif focus != null:
			model.position = Vector3(focus.position.x, 0.0, focus.position.z)
		if SEEDLING_NODES.has(form):
			for stage_name in SEEDLING_NODES.values():
				var stage_node := model.find_child(String(stage_name), true, false) as Node3D
				if stage_node != null:
					stage_node.visible = stage_name == SEEDLING_NODES[form]
		model.show()

## The dated stage variant of a garden plant's model (M3-99: green pods, senescent, dry), or `fallback` when the
## stage has none. Data: res://assets/plants/plant_stage_models.json.
static func plant_stage_model(individual: String, stage: String, fallback: String) -> String:
	if _plant_stage_models.is_empty():
		_plant_stage_models = JSON.parse_string(FileAccess.get_file_as_string(PLANT_STAGE_MODELS_PATH))
	var models = _plant_stage_models.get(individual, {})
	return String(models.get(stage, fallback)) if models is Dictionary else fallback

func _node_root(node_name: String) -> Node3D:
	var existing := get_node_or_null(node_name) as Node3D
	if existing != null:
		return existing
	var node := Node3D.new()
	node.name = node_name
	add_child(node)
	return node

func _build_floor_and_walls(contract: Dictionary) -> void:
	var bounds: Array = contract.get("bounds_m", [10.0, 10.0])
	var width := float(bounds[0]) if not _layout.is_empty() else minf(float(bounds[0]), 40.0)
	var depth := float(bounds[1]) if not _layout.is_empty() else minf(float(bounds[1]), 40.0)
	var visible_shell := not _layout.is_empty()
	var floor_color := Color(_layout.get("floor_color", "#192235"))
	_add_box(collision_root, "FloorCollision", Vector3(0, -0.15, 0), Vector3(width, 0.3, depth), floor_color, visible_shell)
	if contract.get("pressure") == "vacuum":
		# A visible apron guard surrounds the bounded training area. Open sky
		# replaces the old invisible room walls; the edge cannot drop the player.
		var rail_height := float(_layout.get("apron_rail_height_m", 0.9))
		for z in [-depth * 0.5, depth * 0.5]:
			_add_box(collision_root, "ApronRail", Vector3(0, rail_height * 0.5, z), Vector3(width, rail_height, 0.1), Color("#7A7672"), true)
		for x in [-width * 0.5, width * 0.5]:
			_add_box(collision_root, "ApronRail", Vector3(x, rail_height * 0.5, 0), Vector3(0.1, rail_height, depth), Color("#7A7672"), true)
		return
	var height := float(_layout.get("ceiling_height_m", 3.0))
	var wall_color := Color(_layout.get("wall_color", "#263650"))
	_add_box(collision_root, "NorthWallCollision", Vector3(0, height * 0.5, -depth * 0.5), Vector3(width, height, 0.2), wall_color, visible_shell)
	_add_box(collision_root, "SouthWallCollision", Vector3(0, height * 0.5, depth * 0.5), Vector3(width, height, 0.2), wall_color, visible_shell)
	_add_box(collision_root, "WestWallCollision", Vector3(-width * 0.5, height * 0.5, 0), Vector3(0.2, height, depth), wall_color, visible_shell)
	_add_box(collision_root, "EastWallCollision", Vector3(width * 0.5, height * 0.5, 0), Vector3(0.2, height, depth), wall_color, visible_shell)
	if visible_shell:
		var ceiling := _add_box(collision_root, "CeilingCollision", Vector3(0, height + 0.1, 0), Vector3(width, 0.2, depth), wall_color, true)
		for mesh in ceiling.find_children("*", "MeshInstance3D", true, false):
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _build_doors(contract: Dictionary) -> void:
	if _layout.get("assembly") == "habitat_kit":
		_build_kit_doors()
		return
	var boundaries: Array = contract.get("boundary_ids", [])
	for index in boundaries.size():
		var boundary_id := String(boundaries[index])
		var door := DoorScript.new()
		door.name = "Door_" + boundary_id
		door.set_meta("boundary_id", boundary_id)
		door.set_meta("focus_target", "door:" + boundary_id)
		var shape := CollisionShape3D.new()
		shape.name = "CollisionShape3D"
		var box := BoxShape3D.new()
		box.size = Vector3(1.2, 2.2, 0.18)
		shape.shape = box
		door.add_child(shape)
		door.position = _door_position(boundary_id, index)
		door.setup(boundary_id, boundary_id.begins_with("door_"))
		door_root.add_child(door)
		var label := Label3D.new()
		label.name = "BoundaryLabel"
		label.visible = _layout.is_empty()
		label.text = boundary_id.replace("_", " ").to_upper()
		label.font_size = 24
		label.pixel_size = 0.002
		label.position = Vector3(0.0, 1.3, 0.0)
		door.add_child(label)

func _build_focus_targets(contract: Dictionary) -> void:
	var targets: Array = contract.get("focus_targets", [])
	for raw_target in targets:
		if raw_target is Dictionary:
			_add_focus_target(raw_target)

func _add_focus_target(target: Dictionary) -> Node3D:
	var node := Node3D.new()
	node.name = "Focus_" + String(target.get("target_id", "target"))
	var position: Array = target.get("position", [0.0, 1.0, 0.0])
	node.position = Vector3(float(position[0]), float(position[1]), float(position[2]))
	node.add_to_group("interactable")
	node.set_meta("target_id", String(target.get("target_id", node.name)))
	node.set_meta("focus_label", String(target.get("label", node.name)))
	node.set_meta("asset_id", target.get("asset_id", ""))
	node.set_meta("verb", String(target.get("verb", "Inspect")))
	node.set_meta("room_id", room_id)
	focus_root.add_child(node)
	var label := Label3D.new()
	label.text = String(target.get("label", node.name))
	label.position = Presentation.vector(target.get("label_offset", [0, 0.7, 0]))
	label.font_size = 32
	label.pixel_size = 0.0012
	label.fixed_size = true
	label.hide()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.add_child(label)
	return node

## Adds one chapter-staging station (RoomContract.staging focus_targets) with its selection frame around the
## staged object named by asset_id. Removed again by remove_staged_focus_targets().
func add_staged_focus_target(target: Dictionary) -> Node3D:
	var node := _add_focus_target(target)
	node.set_meta("chapter_staging", true)
	var staged := visual_root.get_node_or_null(Staging.ROOT_NAME)
	var asset: Node3D = null
	if staged != null:
		asset = staged.get_node_or_null(String(target.get("asset_id", ""))) as Node3D
	if asset != null and not _selection_frames.has(String(target.target_id)):
		var frame := Presentation.selection_frame(asset, AssetGeometryScript.bounds(asset))
		frame.hide()
		frame.set_meta("chapter_staging", true)
		_selection_frames[String(target.target_id)] = frame
	return node

## Removes every staged station and its selection frame.
func remove_staged_focus_targets() -> void:
	for node in focus_root.get_children():
		if node.has_meta("chapter_staging"):
			var id := String(node.get_meta("target_id", ""))
			var frame = _selection_frames.get(id)
			if frame != null and is_instance_valid(frame) and frame.has_meta("chapter_staging"):
				_selection_frames.erase(id)
			focus_root.remove_child(node)
			node.queue_free()

func _build_pressure_markers(contract: Dictionary) -> void:
	for raw_boundary in contract.get("boundary_ids", []):
		var boundary_id := String(raw_boundary)
		var marker := Node3D.new()
		marker.name = "PressureBoundary_" + boundary_id
		marker.set_meta("boundary_id", boundary_id)
		marker.set_meta("pressure_logic_owner", "WorldRoute")
		marker.set_meta("closed_state_blocks_movement", true)
		pressure_root.add_child(marker)

func _build_anchors(contract: Dictionary) -> void:
	var anchors: Dictionary = contract.get("anchors", {})
	for anchor_id in anchors.keys():
		var marker := Marker3D.new()
		marker.name = String(anchor_id)
		var position: Array = anchors[anchor_id]
		marker.position = Vector3(float(position[0]), float(position[1]), float(position[2]))
		marker.set_meta("anchor_id", String(anchor_id))
		marker.set_meta("room_id", room_id)
		anchor_root.add_child(marker)

func _build_navigation(contract: Dictionary) -> void:
	var bounds: Array = contract.get("bounds_m", [10.0, 10.0])
	var width := minf(float(bounds[0]), 40.0) - 0.8
	var depth := minf(float(bounds[1]), 40.0) - 0.8
	var region := NavigationRegion3D.new()
	region.name = "NavigationRegion"
	var mesh := NavigationMesh.new()
	mesh.vertices = PackedVector3Array([
		Vector3(-width * 0.5, 0.0, -depth * 0.5),
		Vector3(width * 0.5, 0.0, -depth * 0.5),
		Vector3(width * 0.5, 0.0, depth * 0.5),
		Vector3(-width * 0.5, 0.0, depth * 0.5),
	])
	mesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	region.navigation_mesh = mesh
	region.set_meta("route_contract", room_id)
	navigation_root.add_child(region)

func _load_approved_assets(contract: Dictionary) -> void:
	var paths: Array = _layout.get("props", []) if _layout.get("assembly") == "habitat_kit" else contract.get("asset_paths", [])
	for index in paths.size():
		_add_approved_asset(String(paths[index].path) if paths[index] is Dictionary else String(paths[index]), index, paths.size(), paths[index] if paths[index] is Dictionary else {})

## Loads approved prop instances over frames using the existing geometry cache.
func load_assets_incremental() -> void:
	var paths: Array = _layout.get("props", []) if _layout.get("assembly") == "habitat_kit" else RoomContract.room(room_id).get("asset_paths", [])
	for index in paths.size():
		_add_approved_asset(String(paths[index].path) if paths[index] is Dictionary else String(paths[index]), index, paths.size(), paths[index] if paths[index] is Dictionary else {})
		await get_tree().process_frame
	if RoomContract.room(room_id).get("pressure") == "vacuum":
		_style_vacuum(visual_root)
	_build_selection_frames(RoomContract.room(room_id))

func _add_approved_asset(path: String, index: int, count: int, authored: Dictionary = {}) -> void:
	var asset_name := String(authored.get("id", path.get_file().get_basename()))
	if visual_root.has_node(asset_name):
		return
	var model := AssetGeometryScript.load_glb(path)
	if model == null:
		return
	model.name = asset_name
	var transform_data: Dictionary = authored
	for prop in _layout.get("props", []):
		if prop.id == String(model.name):
			transform_data = prop
			break
	if not transform_data.is_empty():
		model.position = Presentation.vector(transform_data.position)
		model.rotation_degrees = Presentation.vector(transform_data.rotation_degrees)
		model.scale = Presentation.vector(transform_data.scale)
	else:
		# Later-chapter staging is still owned by its room/art tasks.
		model.position = _asset_position(index, count)
		model.scale = Vector3.ONE * 0.85
	visual_root.add_child(model)
	if _layout.get("assembly") != "habitat_kit":
		ToonMaterialsScript.apply_to_tree(model, false, true)

func _asset_position(index: int, count: int) -> Vector3:
	var column := index % 3
	var row := index / 3
	return Vector3(float(column - 1) * 2.4, 0.0, -1.4 + float(row) * 2.1)

func _door_position(boundary_id: String, index: int) -> Vector3:
	match boundary_id:
		"door_commons_service", "door_service_garden":
			return Vector3(-2.0 + float(index) * 0.5, 1.1, -5.5 if room_id == "LOC-01" else -2.8)
		"door_commons_garden":
			return Vector3(2.0, 1.1, -5.5)
		"door_commons_safe", "door_service_safe":
			return Vector3(5.5 if room_id == "LOC-01" else 2.8, 1.1, 1.0)
		"garden_viewing_shutter":
			return Vector3(0.0, 1.1, -3.8)
		"airlock_exterior":
			return Vector3(0.0, 1.1, 5.5)
		_:
			return Vector3(-3.0 + float(index), 1.1, 0.0)

func _add_box(parent: Node3D, node_name: String, at: Vector3, size: Vector3, color: Color, visible: bool) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	if visible:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = size
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.88
		box.material = material
		mesh.mesh = box
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(mesh)
		ToonMaterialsScript.apply_to_mesh(mesh, false, false)
	parent.add_child(body)
	return body

func _build_selection_frames(contract: Dictionary) -> void:
	for spec in contract.get("focus_targets", []):
		if _selection_frames.has(String(spec.target_id)):
			continue
		var asset := visual_root.get_node_or_null(String(spec.get("asset_id", ""))) as Node3D
		if asset == null:
			continue
		var frame := Presentation.selection_frame(asset, AssetGeometryScript.bounds(asset))
		frame.hide()
		_selection_frames[String(spec.target_id)] = frame

## Highlights only the current in-range interaction target.
func set_focus_target(id: String) -> void:
	if id == _focus_id:
		return
	_focus_id = id
	for key in _selection_frames:
		_selection_frames[key].visible = key == id
	for node in focus_root.get_children():
		if node.get_child_count() > 0:
			(node.get_child(0) as Label3D).visible = node.get_meta("target_id", "") == id

## The authored fixture spec (position, size, colour, cue) with this id, or {} if absent.
func fixture(id: String) -> Dictionary:
	for spec in _layout.get("fixtures", []):
		if String(spec.get("id", "")) == id:
			return spec.duplicate(true)
	return {}

## True when an installed PR_CrewSeat's sitting position is at this floor point, so a seated
## companion needs no stand-in bench. The sitter's origin is SEAT_SIT_OFFSET_M in front of
## the seat pivot (measured from the approved PR_CrewSeat cushion and backrest).
func has_installed_seat_at(at: Vector3) -> bool:
	for prop in _layout.get("props", []):
		if not prop is Dictionary or String(prop.get("path", "")).get_file() != "PR_CrewSeat.glb":
			continue
		var yaw := deg_to_rad(float(prop.get("rotation_degrees", [0, 0, 0])[1]))
		var sit := Presentation.vector(prop.position) + Basis(Vector3.UP, yaw) * Vector3(0, 0, SEAT_SIT_OFFSET_M)
		if Vector2(sit.x - at.x, sit.z - at.z).length() < 0.15:
			return true
	return false

## Stages the room for one scene: applies the chapter staging that RoomContract.staging reports for it (dated
## furniture, the scene's prop states and light level, stations, collision and a rebuilt navigation map; see
## room_staging.gd), then plays the room's authored fixture cues, e.g. the shared inventory lamp's single blink at
## the CH01 S02→S03 join (doc 24 §2.9; fixture "cue" in the room JSON). Presentation only: repeating the same
## scene cannot restart a cue or change progression. Returns the number of cues started.
func set_scene_context(scene_id: String) -> int:
	if _scene_context == scene_id or visual_root == null:
		return 0
	_scene_context = scene_id
	_apply_staging()
	var started := 0
	for fixture in _layout.get("fixtures", []):
		var cue: Dictionary = fixture.get("cue", {})
		if not cue.get("delay_s", {}).has(scene_id):
			continue
		var lamp := visual_root.get_node_or_null(String(fixture.id)) as MeshInstance3D
		var material := lamp.material_override as StandardMaterial3D if lamp != null else null
		if material == null:
			continue
		var pulse: Array = cue.get("pulse_s", [0.2, 0.5, 0.3])
		var blink := create_tween()
		blink.tween_interval(float(cue.delay_s[scene_id]))
		blink.tween_property(material, "albedo_color", Color(cue.lit_color), float(pulse[0]))
		blink.tween_interval(float(pulse[1]))
		blink.tween_property(material, "albedo_color", Color(fixture.color), float(pulse[2]))
		started += 1
	return started

## Records the story choices (story_log.choices: choice_id -> {"option_id", ...}) that gate echo staging, e.g. the
## 2034 record Ferreira leaves at her place (doc 24 §5.2 D9), and re-stages the current scene if they change it.
func set_story_choices(choices: Dictionary) -> void:
	_choices = choices.duplicate(true)
	if not _scene_context.is_empty():
		_apply_staging()

## The chapter staging applied for the current scene (RoomContract.staging), or {} before any scene context.
func stage() -> Dictionary:
	return _stage

## The scene this room is staged for ("" before set_scene_context).
func scene_context() -> String:
	return _scene_context

func _apply_staging() -> void:
	var next := RoomContract.staging_for(_layout, _scene_context, _choices)
	var signature := JSON.stringify(next)
	if signature == _stage_signature:
		return
	var changes_floor: bool = not _stage.get("obstacles", []).is_empty() or not _stage.get("hide", []).is_empty() or not next.obstacles.is_empty() or not next.hide.is_empty()
	if not _stage.is_empty():
		Staging.clear(self)
	_stage = next
	_stage_signature = signature
	if not next.layers.is_empty():
		Staging.build(self, next, _layout)
	if changes_floor and build_navigation and _layout.get("assembly") == "habitat_kit":
		_rebuild_navigation(RoomContract.staged_layout_for(_layout, _scene_context, _choices))

## Swaps the room's private navigation map for one built from the staged obstacles (same rasteriser and agent
## clearance as the base room, so staged furniture is walked around like Chapter 1 furniture).
func _rebuild_navigation(layout: Dictionary) -> void:
	for region in navigation_root.get_children():
		var map: RID = region.get_meta("private_navigation_map", RID())
		navigation_root.remove_child(region)
		region.free()
		if map.is_valid():
			NavigationServer3D.free_rid(map)
	Habitat.navigation(navigation_root, layout)

func _style_vacuum(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var material = node.get_active_material(surface)
			if material is ShaderMaterial and material.shader == ToonMaterialsScript.WORLD_SHADER:
				material.set_shader_parameter("shadow_color", Color("#040508"))
				material.set_shader_parameter("band_1", 0.02)
				material.set_shader_parameter("band_2", 0.06)
				material.set_shader_parameter("band_softness", 0.003)
	for child in node.get_children():
		_style_vacuum(child)

func _build_kit_doors() -> void:
	for portal in _layout.portals:
		var door := KitDoor.new()
		door.name = "Door_" + String(portal.boundary_id)
		var yaw := Habitat.wall_yaw(String(portal.wall))
		var module_at := Habitat.wall_point(_layout, String(portal.wall), float(portal.offset_m))
		var basis := Basis(Vector3.UP, deg_to_rad(yaw))
		door.position = module_at + basis * Vector3(-0.5, 1.05, 0)
		door.rotation.y = deg_to_rad(yaw)
		var shape := CollisionShape3D.new()
		shape.name = "CollisionShape3D"
		var box := BoxShape3D.new()
		box.size = Vector3(1.2, 2.1, 0.18)
		shape.shape = box
		door.add_child(shape)
		door.set_meta("boundary_id", portal.boundary_id)
		door.setup(String(portal.boundary_id), String(portal.boundary_id).begins_with("door_"))
		door_root.add_child(door)
		var module := Kit.place(door, "EN_Kit_DoorFrame", Vector3(0.5, -1.05, 0))
		door.bind_module(module)
		# Kit modules face local -Z (into the room); a Label3D reads along +Z, so the
		# header plate turns half a revolution and is single-sided (never mirrored).
		var plate := Label3D.new()
		plate.name = "DestinationSign"
		plate.text = String(portal.destination).to_upper()
		plate.position = Vector3(0, 1.25, -0.2)
		plate.rotation.y = PI
		plate.double_sided = false
		plate.font_size = 38
		plate.pixel_size = 0.002
		plate.modulate = Color(_layout.get("accent_color", "#ffffff"))
		door.add_child(plate)
	# The shutter controls a view, never the room's pressure glazing or a walking exit.
	if room_id == "LOC-03":
		var shutter := DoorScript.new()
		shutter.name = "Door_garden_viewing_shutter"
		shutter.set_meta("boundary_id", "garden_viewing_shutter")
		shutter.setup("garden_viewing_shutter", false)
		door_root.add_child(shutter)

func _exit_tree() -> void:
	if navigation_root != null:
		for region in navigation_root.get_children():
			if region.has_meta("private_navigation_map"):
				NavigationServer3D.free_rid(region.get_meta("private_navigation_map"))
