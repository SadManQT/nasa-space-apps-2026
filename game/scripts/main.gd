extends Node3D

const CAMPAIGN_SCENE: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const SaveScript = preload("res://scripts/save/save_service.gd")
const CampaignScript = preload("res://scripts/campaign/chapter1_campaign.gd")
const LegacySliceState = preload("res://scripts/campaign/slice_state.gd")

var _stage_camera: Camera3D
var _stage_root: Node3D
var _menu_layer: CanvasLayer
var _menu: MainMenu
var _campaign: Node3D
var _replace_dialog: ConfirmationDialog
var _save_service: SaveService
var _load_notice := ""
var save_path: String = SaveScript.DEFAULT_PATH
var legacy_save_path: String = LegacySliceState.SAVE_PATH

func _ready() -> void:
	_save_service = _new_save_service()
	_build_stage()
	_show_title()

func _build_stage() -> void:
	_stage_root = Node3D.new()
	_stage_root.name = "TitleStage"
	add_child(_stage_root)
	var environment := WorldEnvironment.new()
	environment.environment = load("res://environments/look/character_look.tres") as Environment
	_stage_root.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, -28, 0)
	key.light_color = Color("#FFE5B5")
	key.light_energy = 1.8
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 50.0
	_stage_root.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 142, 0)
	fill.light_color = Color("#9CC7FF")
	fill.light_energy = 0.7
	_stage_root.add_child(fill)
	_stage_camera = Camera3D.new()
	_stage_camera.position = Vector3(0.0, 2.7, 8.4)
	_stage_camera.fov = 42.0
	_stage_camera.current = true
	_stage_root.add_child(_stage_camera)
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
	_stage_root.add_child(title)

func _show_title() -> void:
	if _campaign != null and is_instance_valid(_campaign):
		_campaign.queue_free()
		_campaign = null
	_stage_root.process_mode = Node.PROCESS_MODE_INHERIT
	_stage_root.show()
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
	_menu.setup(_load_campaign_snapshot())
	_show_load_notice()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _start_new_expedition() -> void:
	if _save_slot_exists():
		_replace_dialog = ConfirmationDialog.new()
		_replace_dialog.title = "Replace existing checkpoint files?"
		_replace_dialog.dialog_text = (
			"This slot already contains an expedition. Starting here "
			+ "will replace that save."
		)
		_replace_dialog.ok_button_text = "REPLACE SAVE"
		_replace_dialog.cancel_button_text = "CANCEL"
		_replace_dialog.confirmed.connect(func() -> void:
			_save_service.clear(save_path)
			LegacySliceState.clear_save(legacy_save_path)
			_launch_campaign({})
		)
		_menu.add_child(_replace_dialog)
		_replace_dialog.popup_centered(Vector2(520, 210))
		return
	_launch_campaign({})

func _continue_expedition() -> void:
	var snapshot := _load_campaign_snapshot()
	if snapshot.is_empty():
		_menu.setup({})
		_show_load_notice()
		return
	_launch_campaign(snapshot)

func _launch_campaign(snapshot: Dictionary) -> void:
	var settings := _menu.accessibility_settings() if is_instance_valid(_menu) else {}
	_stage_root.hide()
	_stage_root.process_mode = Node.PROCESS_MODE_DISABLED
	if _menu_layer != null:
		_menu_layer.queue_free()
		_menu_layer = null
	_campaign = CAMPAIGN_SCENE.instantiate()
	_campaign.set("initial_snapshot", snapshot)
	_campaign.set("initial_accessibility", settings)
	_campaign.set("save_path", save_path)
	_campaign.connect("exit_requested", _show_title)
	add_child(_campaign)
	_stage_camera.current = false

func _load_campaign_snapshot() -> Dictionary:
	_load_notice = ""
	if _save_service == null:
		_save_service = _new_save_service()
	var saved: Dictionary = _save_service.load(save_path)
	if bool(saved.get("accepted", false)):
		if bool(saved.get("recovered", false)):
			_load_notice = "Recovered checkpoint from backup."
			if not bool(saved.get("repair_accepted", true)):
				_load_notice += " Primary repair failed: " + String(saved.get("repair_reason", "unknown error"))
		return saved.get("snapshot", {}).duplicate(true)
	if FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path + ".bak"):
		_load_notice = "Checkpoint could not be opened. Saved files are preserved; New Expedition requires explicit replacement."
	elif FileAccess.file_exists(legacy_save_path):
		_load_notice = "Legacy commissioning checkpoint preserved. Its physical route cannot safely resume; choose New Expedition to replace it deliberately."
	return {}

## Continue only offers a checkpoint the campaign can actually resume; an
## unresumable primary falls back to the verified backup.
func _new_save_service() -> SaveService:
	var service: SaveService = SaveScript.new()
	service.session_validator = func(snapshot: Dictionary) -> Dictionary: return CampaignScript.restore_session(snapshot)
	return service

func _save_slot_exists() -> bool:
	return FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path + ".bak") or FileAccess.file_exists(legacy_save_path)

func _show_load_notice() -> void:
	if not _load_notice.is_empty() and is_instance_valid(_menu):
		var note := _menu.get("_save_note") as Label
		if note != null:
			note.text = _load_notice

func _open_showcase() -> void:
	get_tree().change_scene_to_file("res://scenes/dev/asset_showcase.tscn")

func _add_model(path: String, position: Vector3, scale_value: float) -> void:
	var model := AssetGeometry.load_glb(path)
	if model == null:
		return
	model.position = position
	model.scale = Vector3.ONE * scale_value
	_stage_root.add_child(model)
	ToonMaterials.apply_to_tree(model, false, true)

func _add_box(position: Vector3, size: Vector3, color: Color, emissive: bool) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position
	_stage_root.add_child(body)
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
