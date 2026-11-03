extends Node3D

const CAMPAIGN_SCENE: PackedScene = preload("res://scenes/campaign/ch01_commissioning.tscn")
const MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")

var _stage_camera: Camera3D
var _menu_layer: CanvasLayer
var _menu: MainMenu
var _campaign: Node3D
var _replace_dialog: ConfirmationDialog

func _ready() -> void:
	_build_stage()
	_show_title()

func _build_stage() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = load("res://environments/look/character_look.tres") as Environment
	add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, -28, 0)
	key.light_color = Color("#FFE5B5")
	key.light_energy = 1.8
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 50.0
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 142, 0)
	fill.light_color = Color("#9CC7FF")
	fill.light_energy = 0.7
	add_child(fill)
	_stage_camera = Camera3D.new()
	_stage_camera.position = Vector3(0.0, 2.7, 8.4)
	_stage_camera.fov = 42.0
	_stage_camera.current = true
	add_child(_stage_camera)
	_stage_camera.look_at(Vector3(0.0, 1.0, 0.0))
	_add_box(Vector3(0.0, -0.24, 0.0), Vector3(14.0, 0.45, 9.0), Color("#1B2435"), false)
	_add_box(Vector3(0.0, 2.2, -2.7), Vector3(11.0, 4.3, 0.18), Color("#273651"), false)
	_add_box(Vector3(-5.8, 1.3, 0.2), Vector3(0.18, 2.6, 5.4), Color("#243149"), false)
	_add_box(Vector3(5.8, 1.3, 0.2), Vector3(0.18, 2.6, 5.4), Color("#243149"), false)
	for x in [-4.2, -2.1, 0.0, 2.1, 4.2]:
		_add_box(Vector3(x, 2.0, -2.55), Vector3(1.2, 0.04, 0.04), Color("#F2C230"), true)
	_add_model("res://assets/props/PR_MissionTable/PR_MissionTable.glb", Vector3(0.0, 0.0, -0.4), 1.0)
	_add_model("res://assets/props/PR_BatteryJar/PR_BatteryJar.glb", Vector3(2.4, 0.0, -0.9), 0.82)
	_add_model("res://assets/props/PR_SeedPacket/PR_SeedPacket.glb", Vector3(-2.2, 0.0, -0.75), 0.9)
	var title := Label3D.new()
	title.text = "AURORA  /  COMMISSIONING"
	title.position = Vector3(0.0, 2.05, -2.42)
	title.font_size = 52
	title.pixel_size = 0.0035
	title.modulate = Color("#ECEEF0")
	title.outline_size = 12
	add_child(title)

func _show_title() -> void:
	if _campaign != null and is_instance_valid(_campaign):
		_campaign.queue_free()
		_campaign = null
	_stage_camera.current = true
	_menu_layer = CanvasLayer.new()
	_menu_layer.name = "TitleLayer"
	add_child(_menu_layer)
	_menu = MENU_SCENE.instantiate() as MainMenu
	_menu_layer.add_child(_menu)
	_menu.new_expedition_requested.connect(_start_new_expedition)
	_menu.continue_requested.connect(_continue_expedition)
	_menu.science_requested.connect(_menu.open_science)
	_menu.showcase_requested.connect(_open_showcase)
	_menu.setup(SliceState.load_snapshot())
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _start_new_expedition() -> void:
	if SliceState.has_save():
		_replace_dialog = ConfirmationDialog.new()
		_replace_dialog.title = "Replace verified checkpoint?"
		_replace_dialog.dialog_text = (
			"This slot already contains an expedition. Starting here "
			+ "will replace that save."
		)
		_replace_dialog.ok_button_text = "REPLACE SAVE"
		_replace_dialog.cancel_button_text = "CANCEL"
		_replace_dialog.confirmed.connect(func() -> void:
			SliceState.clear_save()
			_launch_campaign({})
		)
		_menu.add_child(_replace_dialog)
		_replace_dialog.popup_centered(Vector2(520, 210))
		return
	_launch_campaign({})

func _continue_expedition() -> void:
	var snapshot := SliceState.load_snapshot()
	if snapshot.is_empty():
		_menu.setup({})
		return
	_launch_campaign(snapshot)

func _launch_campaign(snapshot: Dictionary) -> void:
	if _menu_layer != null:
		_menu_layer.queue_free()
		_menu_layer = null
	_campaign = CAMPAIGN_SCENE.instantiate()
	_campaign.set("initial_snapshot", snapshot)
	_campaign.connect("exit_requested", _show_title)
	add_child(_campaign)
	_stage_camera.current = false

func _open_showcase() -> void:
	get_tree().change_scene_to_file("res://scenes/dev/asset_showcase.tscn")

func _add_model(path: String, position: Vector3, scale_value: float) -> void:
	var model := AssetGeometry.load_glb(path)
	if model == null:
		return
	model.position = position
	model.scale = Vector3.ONE * scale_value
	add_child(model)
	ToonMaterials.apply_to_tree(model, false, true)

func _add_box(position: Vector3, size: Vector3, color: Color, emissive: bool) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.6
	box.material = material
	mesh.mesh = box
	body.add_child(mesh)
	return body
