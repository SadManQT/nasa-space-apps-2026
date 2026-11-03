extends Node3D

signal exit_requested

const HUD_SCENE: PackedScene = preload("res://scenes/ui/slice_hud.tscn")

var initial_snapshot: Dictionary = {}
var content: Dictionary = {}
var state: Dictionary = {}
var checkpoint: Dictionary = {}
var selected_choice := ""
var hud: SliceHUD
var player: PlayerController
var _table_target: StaticBody3D

func _ready() -> void:
	content = CampaignContent.load_slice()
	var validation := CampaignContent.validate(content)
	if not bool(validation.get("valid", false)):
		push_error("Commissioning content validation failed: " + "; ".join(validation.get("errors", [])))
	state = SliceState.copy_snapshot(initial_snapshot) if SliceState.is_compatible(initial_snapshot) else SliceState.new_snapshot()
	checkpoint = SliceState.copy_snapshot(state)
	player = get_node_or_null("Player") as PlayerController
	_build_room()
	_build_hud()
	if state.get("status", "") == "commissioning_slice_complete":
		hud.show_completion(state)
	else:
		_show_current_scene()
	SliceState.save_snapshot(state)

func _build_room() -> void:
	_add_box(Vector3(0.0, -0.22, 0.0), Vector3(12.0, 0.4, 9.0), Color("#28354A"))
	_add_box(Vector3(0.0, 2.15, -4.15), Vector3(12.0, 4.3, 0.25), Color("#35435B"))
	_add_box(Vector3(-5.85, 1.1, 0.0), Vector3(0.25, 2.2, 8.5), Color("#2D3C55"))
	_add_box(Vector3(5.85, 1.1, 0.0), Vector3(0.25, 2.2, 8.5), Color("#2D3C55"))
	_add_box(Vector3(0.0, 0.1, -3.95), Vector3(10.0, 0.04, 0.04), Color("#F2C230"), true)
	_add_box(Vector3(-5.7, 1.0, -1.1), Vector3(0.04, 1.8, 1.4), Color("#20B8C9"), true)
	_add_box(Vector3(5.7, 1.0, 1.1), Vector3(0.04, 1.8, 1.4), Color("#F26B21"), true)
	_add_asset("res://assets/props/PR_MissionTable/PR_MissionTable.glb", Vector3(0.0, 0.0, -0.75), 1.0)
	_add_asset("res://assets/props/PR_ControlConsole/PR_ControlConsole.glb", Vector3(-3.2, 0.0, -1.7), 0.88)
	_add_asset("res://assets/props/PR_BatteryJar/PR_BatteryJar.glb", Vector3(2.5, 0.0, -1.55), 0.8)
	_add_asset("res://assets/props/PR_SeedPacket/PR_SeedPacket.glb", Vector3(3.3, 0.0, 0.05), 0.75)
	_add_asset("res://assets/props/PR_CrewSeat/PR_CrewSeat.glb", Vector3(-2.5, 0.0, 1.0), 0.9)
	_table_target = _add_interactable(Vector3(0.0, 0.9, 0.05), Vector3(2.3, 1.5, 1.8), "Mission table / commissioning decision")
	_add_interactable(Vector3(2.9, 0.75, 0.0), Vector3(1.0, 1.4, 1.0), "Dry-storage packet / evidence")
	_add_label("MISSION TABLE", Vector3(0.0, 1.95, -0.95), Color("#F2C230"))
	_add_label("CONTROL CONSOLE", Vector3(-3.2, 1.6, -1.8), Color("#20B8C9"))
	_add_label("SIMULATED · TRAINING SCENARIO", Vector3(0.0, 2.5, -3.92), Color("#A8B4C8"), 28)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CampaignHUDLayer"
	add_child(layer)
	hud = HUD_SCENE.instantiate() as SliceHUD
	layer.add_child(hud)
	hud.choice_selected.connect(_on_choice_selected)
	hud.preview_requested.connect(_preview_choice)
	hud.confirm_requested.connect(_commit_choice)
	hud.advance_requested.connect(_advance_after_result)
	hud.retry_requested.connect(_retry_checkpoint)
	hud.exit_requested.connect(func() -> void: exit_requested.emit())

func _show_current_scene() -> void:
	var scene := CampaignContent.scene_at(content, int(state.get("scene_index", 0)))
	if scene.is_empty():
		push_error("No commissioning scene for index " + str(state.get("scene_index", 0)))
		return
	checkpoint = SliceState.copy_snapshot(state)
	selected_choice = ""
	hud.show_scene(scene, state)

func _on_choice_selected(choice_id: String) -> void:
	selected_choice = choice_id
	hud.select_choice(choice_id)

func _preview_choice() -> void:
	var result_bundle := SliceRules.preview(state, int(state.get("state_revision", 0)), selected_choice)
	hud.show_preview(result_bundle.result)

func _commit_choice() -> void:
	var command_id := "%s:%s:%d" % [String(state.get("scene_id", "")), selected_choice, int(state.get("state_revision", 0))]
	var result_bundle := SliceRules.commit(state, command_id, int(state.get("state_revision", 0)), selected_choice)
	var result: Dictionary = result_bundle.result
	if bool(result.get("accepted", false)):
		state = result_bundle.snapshot
		SliceState.save_snapshot(state)
	hud.show_result(result, state)

func _advance_after_result() -> void:
	if state.get("status", "") == "commissioning_slice_complete":
		hud.show_completion(state)
		return
	_show_current_scene()

func _retry_checkpoint() -> void:
	state = SliceState.copy_snapshot(checkpoint)
	selected_choice = ""
	SliceState.save_snapshot(state)
	hud.hide_pause()
	_show_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			hud.show_pause()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_J:
			hud.show_journal()
			get_viewport().set_input_as_handled()
	if event.is_action_pressed("interact") and player != null and _table_target != null:
		if player.global_position.distance_to(_table_target.global_position) <= 2.8:
			hud.show_decision()
			get_viewport().set_input_as_handled()

func _add_asset(path: String, position: Vector3, scale_value: float) -> void:
	var asset := AssetGeometry.load_glb(path)
	if asset == null:
		return
	asset.position = position
	asset.scale = Vector3.ONE * scale_value
	add_child(asset)
	ToonMaterials.apply_to_tree(asset, false, true)

func _add_interactable(position: Vector3, size: Vector3, prompt: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_to_group("interactable")
	body.set_meta("action", "Inspect")
	body.set_meta("prompt", prompt)
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	return body

func _add_label(text: String, position: Vector3, color: Color, font_size: int = 34) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = position
	label.font_size = font_size
	label.pixel_size = 0.0035
	label.modulate = color
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _add_box(position: Vector3, size: Vector3, color: Color, emissive: bool = false) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position
	body.collision_layer = 1
	body.collision_mask = 1
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
	material.roughness = 0.86
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.3
	box.material = material
	mesh.mesh = box
	body.add_child(mesh)
	ToonMaterials.apply_to_tree(body, false, true)
	return body
