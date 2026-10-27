extends Node3D

const CharacterSwitcher: Script = preload("res://scripts/player/character_switcher.gd")
const FootMeter: Script = preload("res://scripts/review/foot_slide.gd")
const CATEGORIES: Array[String] = ["characters", "plants", "props", "vehicles", "environment"]
const CAST: Array[String] = CharacterSwitcher.CAST
const CUTSCENE_DIRECTORY: String = "res://assets/cutscenes"
const PLINTH_HEIGHT: float = 0.18
const MAX_ROW_WIDTH: float = 26.0   # long categories wrap, so a visitor sees a whole row from the aisle
const HOLD_PROPS: Array[String] = ["", "PR_VaultCase", "PR_HandLight"]   # a closed case fits between the CarryBox palms at real size

var exhibits: Array[Dictionary] = []
var cast_index: int = 0
var player: PlayerController
var player_prop: HeldProp
var cutscene_files: PackedStringArray = []
var cutscene_buttons: Array[Button] = []
var panel: Control
var video_overlay: Control
var video: VideoStreamPlayer
var _cutscene_list: VBoxContainer
var _video_frame: AspectRatioContainer
var _status: Label
var _hold_scenes: Dictionary = {}
var _cast: Array[Dictionary] = []

func _ready() -> void:
	player = $Player as PlayerController
	_build_exhibits()
	_build_ui()
	_attach_player_prop()
	print("SHOWCASE loaded %d assets" % exhibits.size())

static func asset_paths(category: String) -> PackedStringArray:
	var paths := PackedStringArray()
	var directory := "res://assets/" + category
	for folder in DirAccess.get_directories_at(directory):
		var path := directory.path_join(folder).path_join(folder + ".glb")
		if FileAccess.file_exists(path):
			paths.append(path)
	paths.sort()
	return paths

static func display_name(asset: String) -> String:
	return asset.substr(asset.find("_") + 1).to_snake_case().replace("_", " ").capitalize()

func _build_exhibits() -> void:
	var row_front := 1.0
	var hall_width := 18.0
	for category in CATEGORIES:
		var area := Node3D.new()
		area.name = category.capitalize()
		add_child(area)
		var row: Array[Dictionary] = []
		var gap := 3.0 if category == "vehicles" else 1.5
		for path in asset_paths(category):
			var model := AssetGeometry.load_glb(path)
			if model == null:
				continue
			area.add_child(model)
			model.name = path.get_file().get_basename()
			ToonMaterials.apply_to_tree(model, category == "characters", true)
			if category == "characters":
				_setup_character(model)
			var bounds := AssetGeometry.bounds(model, category == "characters")
			var size := Vector3(maxf(bounds.size.x + 0.6, 1.6), PLINTH_HEIGHT, maxf(bounds.size.z + 0.6, 1.4))
			row.append({"path": path, "category": category, "model": model, "bounds": bounds, "size": size})
		var lines: Array = [[]]
		var line_width := 0.0
		for entry in row:
			if not lines[-1].is_empty() and line_width + entry.size.x > MAX_ROW_WIDTH:
				lines.append([])
				line_width = 0.0
			lines[-1].append(entry)
			line_width += entry.size.x + gap
		for line_index in lines.size():
			var width := -gap
			var depth := 1.0
			for entry in lines[line_index]:
				width += entry.size.x + gap
				depth = maxf(depth, entry.size.z)
			var x := -width * 0.5
			for entry in lines[line_index]:
				var model: Node3D = entry.model
				var bounds: AABB = entry.bounds
				var size: Vector3 = entry.size
				var center := Vector3(x + size.x * 0.5, 0.0, row_front - depth * 0.5)
				model.position = center - Vector3(bounds.get_center().x, bounds.position.y - PLINTH_HEIGHT, bounds.get_center().z)
				entry.plinth = _box(area, "Plinth_" + model.name, center + Vector3.UP * PLINTH_HEIGHT * 0.5, size, Color("#435269"))
				# A placard on the plinth's front edge, so no label ever stands between a visitor and a model.
				entry.label = _label(area, display_name(model.name) + "\n" + category.capitalize(), center + Vector3(0.0, PLINTH_HEIGHT + 0.1, size.z * 0.5 - 0.12), 34, true)
				entry.plinth_top = PLINTH_HEIGHT
				# A simple exhibit boundary keeps visitors out of the meshes.
				var barrier := StaticBody3D.new()
				area.add_child(barrier)
				barrier.position = model.position + bounds.get_center()
				var collision := CollisionShape3D.new()
				var shape := BoxShape3D.new()
				shape.size = bounds.size.max(Vector3(0.1, 0.1, 0.1))
				collision.shape = shape
				barrier.add_child(collision)
				exhibits.append(entry)
				x += size.x + gap
			if line_index == 0:
				_label(area, category.to_upper(), Vector3(-width * 0.5 - 2.0, 2.8, row_front + 1.0), 64)
			hall_width = maxf(hall_width, width + 12.0)
			row_front -= depth + 3.5
		row_front -= 1.5
	var length := 14.0 - row_front
	var center_z := (10.0 + row_front - 4.0) * 0.5
	_box(self, "Floor", Vector3(0.0, -0.2, center_z), Vector3(hall_width, 0.4, length), Color("#252d3b"))
	for side in [-1.0, 1.0]:
		_box(self, "SideWall", Vector3(side * hall_width * 0.5, 0.6, center_z), Vector3(0.3, 1.2, length), Color("#617086"))
	_box(self, "BackWall", Vector3(0.0, 0.6, row_front - 4.0), Vector3(hall_width, 1.2, 0.3), Color("#617086"))
	_box(self, "EntranceWall", Vector3(0.0, 0.6, 10.0), Vector3(hall_width, 1.2, 0.3), Color("#617086"))
	for actor in _cast:
		_ground_character(actor)

func _setup_character(model: Node3D) -> void:
	var rig := model.find_child("Skeleton3D", true, false) as Skeleton3D
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if rig == null or players.is_empty():
		push_error("Showcase character has no rig or animation: " + model.name)
		return
	var motion := PlayerAnimation.new()
	model.add_child(motion)
	motion.idle_variations = false
	if not motion.setup(players[0] as AnimationPlayer, rig, LocomotionTuning.new()):
		push_error("Showcase animation setup failed: " + model.name)
		return
	rig.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	var face := FaceAtlas.new()
	face.name = "FaceAtlas"
	model.add_child(face)
	var springs := HairSprings.new()
	springs.name = "HairSprings"
	model.add_child(springs)
	var meter: RefCounted = FootMeter.new()
	meter.setup(model, rig)
	var attachment := HeldProp.new()
	attachment.name = "HeldProp"
	model.add_child(attachment)
	var hold := PlayerAnimation.Hold.BOX if model.name == "CH_Kai" else PlayerAnimation.Hold.RIGHT if model.name == "CH_Rafi" else PlayerAnimation.Hold.NONE
	motion.set_hold(hold)
	motion.advance(PlayerAnimation.HOLD_FADE, 0.0)
	attachment.setup(rig, hold, _hold_scene(hold))
	_cast.append({"model": model, "motion": motion, "rig": rig, "meter": meter, "attachment": attachment})

func _ground_character(actor: Dictionary) -> void:
	var surface: Dictionary = actor.meter.sample(0.0)
	var lowest := minf(surface.left.height, surface.right.height)
	if is_finite(lowest):
		actor.model.position.y += global_position.y + PLINTH_HEIGHT - lowest
	actor.attachment.update_alignment()

func _process(delta: float) -> void:
	for actor in _cast:
		actor.motion.advance(delta, 0.0)
		actor.rig.advance(delta)
		_ground_character(actor)
	_sync_player_hold()
	if video_overlay.visible:
		var texture := video.get_video_texture()
		if texture != null and texture.get_height() > 0:
			_video_frame.ratio = float(texture.get_width()) / texture.get_height()

func _hold_scene(mode: PlayerAnimation.Hold) -> PackedScene:
	if mode == PlayerAnimation.Hold.NONE:
		return null
	if not _hold_scenes.has(mode):
		var asset := HOLD_PROPS[mode]
		var model := AssetGeometry.load_glb("res://assets/props/%s/%s.glb" % [asset, asset])
		if model == null:
			return null
		# Share the styled materials across equip and character-switch cycles.
		ToonMaterials.apply_to_tree(model, false, true)
		var scene := PackedScene.new()
		var error := scene.pack(model)
		model.free()
		if error != OK:
			push_error("Could not pack held prop: " + asset)
			return null
		_hold_scenes[mode] = scene
	return _hold_scenes[mode]

func _attach_player_prop() -> void:
	player_prop = HeldProp.new()
	player_prop.name = "HeldProp"
	player.add_child(player_prop)
	_sync_player_hold()

func _sync_player_hold() -> void:
	if player.animation == null:
		return
	var mode := player.animation.hold_mode
	if player_prop.mode != mode or player_prop.skeleton != player.animation.skeleton:
		player_prop.setup(player.animation.skeleton, mode, _hold_scene(mode))
	_status.text = "%s   |   Hold: %s" % [CAST[cast_index].trim_prefix("CH_"), PlayerAnimation.Hold.keys()[mode]]

func switch_character(index: int) -> void:
	if index < 0 or index >= CAST.size():
		return
	player = CharacterSwitcher.switch_character(player, index)
	cast_index = index
	_attach_player_prop()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if video_overlay.visible:
		if key == KEY_ESCAPE:
			close_video()
		elif key == KEY_SPACE:
			video.paused = not video.paused
	elif panel.visible:
		if key in [KEY_C, KEY_ESCAPE]:
			close_panel()
		else:
			return
	elif key == KEY_C:
		open_panel()
	elif key >= KEY_1 and key < KEY_1 + CAST.size():
		switch_character(key - KEY_1)
	elif key == KEY_TAB:
		switch_character((cast_index + 1) % CAST.size())
	elif key == KEY_H:
		player.set_hold(((player.animation.hold_mode + 1) % PlayerAnimation.Hold.size()) as PlayerAnimation.Hold)
		_sync_player_hold()
	else:
		return
	get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "UI"
	add_child(canvas)
	var hud := VBoxContainer.new()
	hud.position = Vector2(24.0, 18.0)
	hud.add_theme_constant_override("separation", 8)
	canvas.add_child(hud)
	var title := Label.new()
	title.text = "Last Light Academy - Asset Showcase"
	title.add_theme_font_size_override("font_size", 26)
	hud.add_child(title)
	var help := Label.new()
	help.text = "WASD move, Shift run, Ctrl sprint, 1-5/Tab character, H hold, C cutscenes, Esc release mouse"
	help.add_theme_font_size_override("font_size", 16)
	hud.add_child(help)
	_status = Label.new()
	hud.add_child(_status)
	var open := Button.new()
	open.text = "Cutscenes (C)"
	open.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	open.pressed.connect(open_panel)
	hud.add_child(open)
	panel = PanelContainer.new()
	canvas.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 60.0
	panel.offset_top = 150.0
	panel.offset_right = -60.0
	panel.offset_bottom = -30.0
	var content := VBoxContainer.new()
	panel.add_child(content)
	var heading := Label.new()
	heading.text = "Cutscenes"
	heading.add_theme_font_size_override("font_size", 24)
	content.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	_cutscene_list = VBoxContainer.new()
	_cutscene_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_cutscene_list)
	var close := Button.new()
	close.text = "Back to hall (C / Esc)"
	close.pressed.connect(close_panel)
	content.add_child(close)
	video_overlay = ColorRect.new()
	video_overlay.color = Color.BLACK
	canvas.add_child(video_overlay)
	video_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_video_frame = AspectRatioContainer.new()
	_video_frame.ratio = 16.0 / 9.0
	_video_frame.stretch_mode = AspectRatioContainer.STRETCH_FIT
	video_overlay.add_child(_video_frame)
	_video_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video = VideoStreamPlayer.new()
	video.expand = true
	video.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	video.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_video_frame.add_child(video)
	video.finished.connect(close_video)
	var skip := Button.new()
	skip.text = "Skip / Esc   |   Space: pause"
	skip.position = Vector2(24.0, 24.0)
	skip.pressed.connect(close_video)
	video_overlay.add_child(skip)
	panel.hide()
	video_overlay.hide()
	refresh_cutscenes()

func refresh_cutscenes(directory: String = CUTSCENE_DIRECTORY) -> void:
	for child in _cutscene_list.get_children():
		child.free()
	cutscene_files.clear()
	cutscene_buttons.clear()
	if DirAccess.dir_exists_absolute(directory):
		for file in DirAccess.get_files_at(directory):
			if file.get_extension().to_lower() == "ogv":
				cutscene_files.append(directory.path_join(file))
	cutscene_files.sort()
	for path in cutscene_files:
		var button := Button.new()
		button.text = path.get_file().get_basename().replace("_", " ")
		button.pressed.connect(play_cutscene.bind(path))
		_cutscene_list.add_child(button)
		cutscene_buttons.append(button)
	if cutscene_files.is_empty():
		var empty := Label.new()
		empty.text = "No cutscenes yet"
		_cutscene_list.add_child(empty)

func open_panel() -> void:
	refresh_cutscenes()
	panel.show()
	player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not cutscene_buttons.is_empty():
		cutscene_buttons[0].grab_focus()

func close_panel() -> void:
	panel.hide()
	player.process_mode = Node.PROCESS_MODE_INHERIT
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func play_cutscene(path: String) -> void:
	if not FileAccess.file_exists(path) or path.get_extension().to_lower() != "ogv":
		return
	var stream := VideoStreamTheora.new()
	stream.file = path
	video.stream = stream
	video.paused = false
	video_overlay.show()
	panel.hide()
	player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	video.play()

func close_video() -> void:
	video.stop()
	video.paused = false
	video.stream = null
	video_overlay.hide()
	open_panel()

func _label(parent: Node, text: String, at: Vector3, font_size: int = 42, placard: bool = false) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = font_size
	label.pixel_size = 0.004
	label.outline_size = 10
	if placard:
		label.rotation_degrees.x = -55.0   # leans back toward the aisle
	else:
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	return label

func _box(parent: Node, label: String, at: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = at
	parent.add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	box.material = material
	mesh.mesh = box
	body.add_child(mesh)
	ToonMaterials.apply_to_tree(body, false, true)
	return body
