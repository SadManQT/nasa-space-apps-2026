extends Node3D
class_name CharacterReview

const CHARACTER_NAMES: Array[String] = ["CH_Kai", "CH_Amara", "CH_Mei", "CH_Rafi", "CH_Ferreira"]
const CHARACTER_ROOT: String = "res://assets/characters/"
const HAND_POSES: Array[String] = ["HandRelaxed", "HandOpen", "HandGrip", "HandFist", "HandPoint", "HandPinch"]
const CAMERAS: Array[String] = ["front", "side", "back", "three-quarter", "face close-up", "left hand", "right hand", "feet", "turntable"]
const FootSlideScript: Script = preload("res://scripts/review/foot_slide.gd")

# Tests supply their own assets after _ready; normal scene runs load --glb or installed Kai.
@export var auto_load: bool = true

const DEFAULT_CUE_PATH: String = "res://tools/test_data/kai_test_visemes.json"
const LipSyncScript: Script = preload("res://scripts/lip_sync.gd")
const ReviewLipOverlayScript: Script = preload("res://scripts/review/lip_overlay.gd")

var _stage: Node3D
var _actor_pivot: Node3D
var _props_container: Node3D
var _camera: Camera3D
var _character: Node3D
var _animation_player: AnimationPlayer
var _skeleton: Skeleton3D
var _bone_lines: MeshInstance3D
var _face_mesh: MeshInstance3D
var _lip_sync: Node
var _audio_player: AudioStreamPlayer
var _attached_prop: Node3D
var _attached_attachment: BoneAttachment3D
var _lip_audio: AudioStream
var _cue_path: String = DEFAULT_CUE_PATH
var _lip_cues: Array[Dictionary] = []
var _lip_duration: float = 0.0
var _lip_overlay: Control
var _file_dialog: FileDialog
var _file_kind: String = "cue"
var _capture_frames_left: int = -1
var _capture_frames_written: int = 0
var _capture_skip_advance: bool = false
var _viewport_container: SubViewportContainer
var _review_viewport: SubViewport
var _ui_root: Control
var _lip_seek: HSlider
var _animation_time: float = 0.0
var _playing: bool = false
var _foot_slide = FootSlideScript.new()
var _measurements: Dictionary = {}
var _capture_spec: Array[String] = []
var _current_character_path: String = ""
var _current_clip: String = ""
var _clip_names: Array[String] = []
var _one_shot: bool = false
var _loop_enabled: bool = true
var _speed: float = 1.0
var _hand_pose_name: String = ""
var _hand_side: String = "both"
var _camera_preset: String = "front"
var _orbit_angle: float = 0.0
var _character_option: OptionButton
var _clip_option: OptionButton
var _camera_option: OptionButton
var _prop_option: OptionButton
var _hand_option: OptionButton
var _hand_side_option: OptionButton
var _play_button: Button
var _scrub: HSlider
var _time_label: Label
var _speed_slider: HSlider
var _speed_label: Label
var _loop_check: CheckBox
var _one_shot_check: CheckBox
var _status_label: Label
var _measurement_label: Label
var _foot_flag_label: Label
var _lip_time_label: Label
var _lip_play_button: Button
var _wireframe_check: CheckBox
var _skeleton_check: CheckBox
var _unshaded_check: CheckBox
var _prop_x: SpinBox
var _prop_y: SpinBox
var _prop_z: SpinBox
var _prop_rx: SpinBox
var _prop_ry: SpinBox
var _prop_rz: SpinBox

func _ready() -> void:
	_build_stage()
	_build_ui()
	_parse_user_args()
	_load_lip_cues(_cue_path)
	if auto_load:
		_load_start_character()
	set_process(true)

func _load_start_character() -> void:
	var path := _user_arg_value("--glb=")
	var cues := _user_arg_value("--cues=")
	if not cues.is_empty():
		_load_lip_cues(cues)
	var audio := _user_arg_value("--audio=")
	if not audio.is_empty():
		_lip_audio = _load_audio(audio)
		_lip_overlay.set_data(_build_waveform(_lip_audio), _lip_cues, _lip_duration)
	if path.is_empty():
		path = CHARACTER_ROOT.path_join("CH_Kai/CH_Kai.glb")
	else:
		# Switching cast stays in the supplied build directory, not installed v3 assets.
		var build_root := path.get_base_dir().get_base_dir()
		for i in CHARACTER_NAMES.size():
			var character := CHARACTER_NAMES[i]
			var sibling := build_root.path_join(character).path_join(character + ".glb")
			_character_option.set_item_metadata(i, sibling)
			_character_option.set_item_disabled(i, not FileAccess.file_exists(sibling))
	if not load_character(path):
		if not _capture_spec.is_empty():
			_capture_error("Could not load " + path)
		return
	if not _capture_spec.is_empty():
		_configure_capture()

func _build_stage() -> void:
	_viewport_container = SubViewportContainer.new()
	add_child(_viewport_container)
	_viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport_container.offset_left = 360.0
	_viewport_container.offset_bottom = -280.0
	_viewport_container.stretch = true
	_review_viewport = SubViewport.new()
	_review_viewport.size = Vector2i(920, 620)
	_review_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport_container.add_child(_review_viewport)
	_stage = Node3D.new()
	_stage.name = "ReviewStage"
	_review_viewport.add_child(_stage)
	_actor_pivot = Node3D.new()
	_actor_pivot.name = "CharacterPivot"
	_stage.add_child(_actor_pivot)
	_props_container = Node3D.new()
	_props_container.name = "PlacedProps"
	_stage.add_child(_props_container)

	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(12.0, 12.0)
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("#73777c")
	ground_material.roughness = 0.92
	plane.material = ground_material
	ground.mesh = plane
	ground.position.y = 0.0
	_stage.add_child(ground)

	var grid := MeshInstance3D.new()
	grid.name = "HalfMeterGrid"
	var grid_mesh := ImmediateMesh.new()
	var grid_material := StandardMaterial3D.new()
	grid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grid_material.albedo_color = Color(0.23, 0.27, 0.3, 0.5)
	grid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_mesh.surface_begin(Mesh.PRIMITIVE_LINES, grid_material)
	for i in range(-12, 13):
		var p := float(i) * 0.5
		grid_mesh.surface_add_vertex(Vector3(p, 0.002, -6.0))
		grid_mesh.surface_add_vertex(Vector3(p, 0.002, 6.0))
		grid_mesh.surface_add_vertex(Vector3(-6.0, 0.002, p))
		grid_mesh.surface_add_vertex(Vector3(6.0, 0.002, p))
	grid_mesh.surface_end()
	grid.mesh = grid_mesh
	_stage.add_child(grid)

	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
	key.light_color = Color("#fff0dc")
	key.light_energy = 1.8
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 25.0
	_stage.add_child(key)
	var fill := OmniLight3D.new()
	fill.name = "SoftFill"
	fill.position = Vector3(-3.0, 3.5, 4.0)
	fill.light_color = Color("#c9ddff")
	fill.light_energy = 1.1
	fill.omni_range = 12.0
	_stage.add_child(fill)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#858a90")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b8bec4")
	env.ambient_light_energy = 0.65
	environment.environment = env
	_stage.add_child(environment)
	_camera = Camera3D.new()
	_camera.name = "ReviewCamera"
	_camera.current = true
	_camera.fov = 40.0
	_stage.add_child(_camera)
	_set_camera_preset("front")

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ReviewUI"
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	_ui_root = root
	var left_panel := PanelContainer.new()
	
	left_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(left_panel)
	left_panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	left_panel.offset_left = 12.0
	left_panel.offset_top = 12.0
	left_panel.offset_right = 348.0
	left_panel.offset_bottom = -12.0
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_panel.add_child(scroll)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 5)
	scroll.add_child(left)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_text(left, "CHARACTER REVIEW", 18)
	_status_label = _add_text(left, "Loading…", 11)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_character_option = _add_option(left, "Character")
	_character_option.item_selected.connect(_on_character_selected)
	for character in CHARACTER_NAMES:
		_character_option.add_item(character)
		_character_option.set_item_metadata(_character_option.item_count - 1, CHARACTER_ROOT.path_join(character + "/" + character + ".glb"))
	_add_text(left, "Camera", 11)
	_camera_option = OptionButton.new()
	for camera_name in CAMERAS:
		_camera_option.add_item(camera_name)
	_camera_option.item_selected.connect(_on_camera_selected)
	left.add_child(_camera_option)
	_add_text(left, "Animation clip", 11)
	_clip_option = OptionButton.new()
	_clip_option.item_selected.connect(_on_clip_selected)
	left.add_child(_clip_option)
	var playback := HBoxContainer.new()
	_play_button = Button.new()
	_play_button.text = "Play"
	_play_button.pressed.connect(_on_play_pressed)
	playback.add_child(_play_button)
	var back := Button.new()
	back.text = "◀ 1/30"
	back.pressed.connect(func() -> void: step_frame(-1))
	playback.add_child(back)
	var forward := Button.new()
	forward.text = "1/30 ▶"
	forward.pressed.connect(func() -> void: step_frame(1))
	playback.add_child(forward)
	left.add_child(playback)
	_scrub = HSlider.new()
	_scrub.min_value = 0.0
	_scrub.max_value = 1.0
	_scrub.step = 0.001
	_scrub.value_changed.connect(_on_scrub_changed)
	left.add_child(_scrub)
	_time_label = _add_text(left, "0.00 / 0.00 s", 10)
	_speed_slider = HSlider.new()
	_speed_slider.min_value = 0.1
	_speed_slider.max_value = 2.0
	_speed_slider.step = 0.1
	_speed_slider.value = 1.0
	_speed_slider.value_changed.connect(_on_speed_changed)
	left.add_child(_speed_slider)
	_speed_label = _add_text(left, "Speed 1.0x", 10)
	_loop_check = CheckBox.new()
	_loop_check.text = "Loop clip"
	_loop_check.button_pressed = true
	_loop_check.toggled.connect(_on_loop_toggled)
	left.add_child(_loop_check)
	_one_shot_check = CheckBox.new()
	_one_shot_check.text = "One-shot / hold last frame"
	_one_shot_check.toggled.connect(_on_one_shot_toggled)
	left.add_child(_one_shot_check)
	_add_text(left, "Hand pose overlay", 11)
	var hand_row := HBoxContainer.new()
	_hand_option = OptionButton.new()
	for pose in ["None"] + HAND_POSES:
		_hand_option.add_item(pose)
	_hand_option.item_selected.connect(_on_hand_pose_selected)
	hand_row.add_child(_hand_option)
	_hand_side_option = OptionButton.new()
	for side in ["both", "left", "right"]:
		_hand_side_option.add_item(side)
	_hand_side_option.item_selected.connect(_on_hand_side_selected)
	hand_row.add_child(_hand_side_option)
	left.add_child(hand_row)
	_add_text(left, "Prop attachment", 11)
	_prop_option = OptionButton.new()
	for category in ["props", "plants", "vehicles"]:
		_add_props_from("res://assets/" + category)
	left.add_child(_prop_option)
	var prop_row := HBoxContainer.new()
	var attach_left := Button.new()
	attach_left.text = "Attach left"
	attach_left.pressed.connect(func() -> void: _attach_selected_prop("left"))
	prop_row.add_child(attach_left)
	var attach_right := Button.new()
	attach_right.text = "Attach right"
	attach_right.pressed.connect(func() -> void: _attach_selected_prop("right"))
	prop_row.add_child(attach_right)
	var place := Button.new()
	place.text = "Place in scene"
	place.pressed.connect(func() -> void: _place_selected_prop())
	prop_row.add_child(place)
	left.add_child(prop_row)
	var clear := Button.new()
	clear.text = "Remove props"
	clear.pressed.connect(clear_props)
	left.add_child(clear)
	var offset_grid := GridContainer.new()
	offset_grid.columns = 6
	for label in ["px", "py", "pz", "rx", "ry", "rz"]:
		_add_text(offset_grid, label, 9)
		var spin := _make_offset_spin()
		if label.begins_with("r"):
			spin.min_value = -180.0
			spin.max_value = 180.0
			spin.step = 1.0
		spin.value_changed.connect(_on_prop_offset_changed)
		offset_grid.add_child(spin)
		match label:
			"px": _prop_x = spin
			"py": _prop_y = spin
			"pz": _prop_z = spin
			"rx": _prop_rx = spin
			"ry": _prop_ry = spin
			"rz": _prop_rz = spin
	left.add_child(offset_grid)
	var debug_row := HBoxContainer.new()
	_wireframe_check = _make_check(debug_row, "Wire", _on_debug_toggled)
	_skeleton_check = _make_check(debug_row, "Skeleton", _on_debug_toggled)
	_unshaded_check = _make_check(debug_row, "Unshaded", _on_debug_toggled)
	left.add_child(debug_row)
	_measurement_label = _add_text(left, "Motion: —", 10)
	_foot_flag_label = _add_text(left, "Foot contact: —", 10)
	_foot_flag_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var lip_panel := PanelContainer.new()
	
	lip_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(lip_panel)
	lip_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	lip_panel.offset_left = 360.0
	lip_panel.offset_top = -268.0
	lip_panel.offset_right = -12.0
	lip_panel.offset_bottom = -12.0
	var lip_box := VBoxContainer.new()
	lip_box.add_theme_constant_override("separation", 4)
	lip_panel.add_child(lip_box)
	_add_text(lip_box, "LIP-SYNC TECHNICAL OVERLAY", 15)
	var lip_buttons := HFlowContainer.new()
	_lip_play_button = Button.new()
	_lip_play_button.text = "Play line"
	_lip_play_button.pressed.connect(_on_lip_play_pressed)
	lip_buttons.add_child(_lip_play_button)
	var lip_pause := Button.new()
	lip_pause.text = "Pause / resume"
	lip_pause.pressed.connect(_on_lip_pause_pressed)
	lip_buttons.add_child(lip_pause)
	var choose_cue := Button.new()
	choose_cue.text = "Choose cue JSON…"
	choose_cue.pressed.connect(func() -> void: _open_file_dialog("cue"))
	lip_buttons.add_child(choose_cue)
	var choose_audio := Button.new()
	choose_audio.text = "Choose audio…"
	choose_audio.pressed.connect(func() -> void: _open_file_dialog("audio"))
	lip_buttons.add_child(choose_audio)
	lip_box.add_child(lip_buttons)
	_lip_seek = HSlider.new()
	_lip_seek.min_value = 0.0
	_lip_seek.max_value = 1.0
	_lip_seek.step = 0.001
	_lip_seek.value_changed.connect(_on_lip_seek_changed)
	lip_box.add_child(_lip_seek)
	_lip_time_label = _add_text(lip_box, "0.00 / 0.00 s", 10)
	_lip_overlay = ReviewLipOverlayScript.new()
	_lip_overlay.custom_minimum_size = Vector2(0.0, 160.0)
	lip_box.add_child(_lip_overlay)

	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.filters = PackedStringArray(["*.json ; Cue JSON", "*.wav ; WAV audio", "*.ogg ; Ogg audio", "*.mp3 ; MP3 audio"])
	_file_dialog.file_selected.connect(_on_file_selected)
	canvas.add_child(_file_dialog)

func _add_option(parent: Container, title: String) -> OptionButton:
	var label := Label.new()
	label.text = title
	parent.add_child(label)
	var option := OptionButton.new()
	parent.add_child(option)
	return option

func _add_text(parent: Container, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _make_check(parent: Container, text: String, callback: Callable) -> CheckBox:
	var check := CheckBox.new()
	check.text = text
	check.toggled.connect(callback)
	parent.add_child(check)
	return check

func _make_offset_spin() -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = -2.0
	spin.max_value = 2.0
	spin.step = 0.01
	spin.custom_minimum_size = Vector2(62.0, 0.0)
	return spin

func _parse_user_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			_capture_spec = arg.trim_prefix("--capture=").split(",", false)

func _user_arg_value(prefix: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""

func load_character(path: String) -> bool:
	var loaded := _instantiate_path(path)
	if loaded == null:
		_set_status("Could not load character: " + path)
		return false
	var players := loaded.find_children("*", "AnimationPlayer", true, false)
	var skeletons := loaded.find_children("*", "Skeleton3D", true, false)
	if players.is_empty() or skeletons.is_empty():
		loaded.free()
		_set_status("Character needs an AnimationPlayer and Skeleton3D")
		return false
	if is_instance_valid(_lip_sync):
		_lip_sync.stop(true)
	if is_instance_valid(_character):
		_character.free()
	_attached_attachment = null
	_attached_prop = null
	_hand_pose_name = ""
	_hand_option.select(0)
	_playing = false
	_actor_pivot.add_child(loaded)
	_character = loaded
	_current_character_path = path
	_animation_player = players[0] as AnimationPlayer
	_animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_skeleton = skeletons[0] as Skeleton3D
	_face_mesh = _find_face_mesh(_character)
	_update_clips()
	_setup_lip_sync()
	_foot_slide.setup(_character, _skeleton)
	select_clip("Idle_loop" if _clip_names.has("Idle_loop") else _clip_names[0])
	for i in _character_option.item_count:
		if String(_character_option.get_item_metadata(i)) == path:
			_character_option.select(i)
	_set_status("Loaded %s (%d clips, %d bones)" % [path.get_file(), _clip_names.size(), _skeleton.get_bone_count()])
	return true

func _instantiate_path(path: String) -> Node3D:
	if path.begins_with("res://") and path.get_extension().to_lower() != "glb":
		var packed := load(path) as PackedScene
		return packed.instantiate() as Node3D if packed != null else null
	if not FileAccess.file_exists(path):
		return null
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	var error: Error = document.append_from_file(path, state)
	if error != OK:
		push_error("GLB import failed (%s): %s" % [error, path])
		return null
	return document.generate_scene(state) as Node3D

func _find_face_mesh(root: Node) -> MeshInstance3D:
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance.mesh != null and mesh_instance.mesh.get_blend_shape_count() > 0:
			return mesh_instance
	return null

func _update_clips() -> void:
	_clip_names.clear()
	_clip_option.clear()
	if _animation_player == null:
		return
	for name in _animation_player.get_animation_list():
		_clip_names.append(String(name))
		_clip_option.add_item(String(name))

func get_clip_names() -> Array[String]:
	return _clip_names.duplicate()

func get_current_animation_time() -> float:
	return _animation_time

func get_current_clip_length() -> float:
	if _animation_player == null or not _animation_player.has_animation(_current_clip):
		return 0.0
	return _animation_player.get_animation(_current_clip).length

func select_clip(name: String) -> bool:
	if _animation_player == null or not _animation_player.has_animation(name):
		return false
	_current_clip = name
	_animation_time = 0.0
	_playing = false
	_apply_loop_mode(name)
	_clip_option.select(_clip_names.find(name))
	_evaluate_pose()
	reset_measurements()
	_update_animation_ui()
	return true

func play_clip(name: String = "") -> bool:
	if not name.is_empty() and not select_clip(name):
		return false
	if _animation_player == null or _current_clip.is_empty():
		return false
	if _animation_time >= get_current_clip_length():
		seek_animation(0.0)
	_playing = true
	_update_animation_ui()
	return true

func pause_clip() -> void:
	_playing = false
	_update_animation_ui()

func is_clip_playing() -> bool:
	return _playing

func step_frame(direction: int) -> void:
	pause_clip()
	seek_animation(_animation_time + float(direction) / 30.0)

func seek_animation(time: float) -> void:
	if _animation_player == null or _current_clip.is_empty():
		return
	_animation_time = clampf(time, 0.0, get_current_clip_length())
	_evaluate_pose()
	reset_measurements()
	_update_animation_ui()

# A single clock drives normal playback, deterministic tests, and MovieWriter.
func advance_playback(delta: float) -> void:
	if not _playing or delta <= 0.0:
		return
	var next_time := _animation_time + delta * _speed
	var length := get_current_clip_length()
	if next_time >= length:
		if _loop_enabled and not _one_shot and length > 0.0:
			next_time = fposmod(next_time, length)
			# Do not count the discontinuity across the loop seam as foot sliding.
			_foot_slide.reset()
		else:
			next_time = length
			_playing = false
	_animation_time = next_time
	_evaluate_pose()
	_measurements = _foot_slide.sample(delta)
	_update_animation_ui()

func _evaluate_pose() -> void:
	# Sparse clips omit some fingers. Reset before sampling so switching a
	# hand clip or removing an overlay cannot leave stale poses on those bones.
	_skeleton.reset_bone_poses()
	_animation_player.play(_current_clip)
	_animation_player.seek(_animation_time, true)
	_animation_player.pause()
	_apply_hand_pose()

func set_one_shot(enabled: bool) -> void:
	_one_shot = enabled
	_one_shot_check.set_pressed_no_signal(enabled)
	_loop_check.disabled = enabled
	_apply_loop_mode(_current_clip)

func set_loop(enabled: bool) -> void:
	_loop_enabled = enabled
	_loop_check.set_pressed_no_signal(enabled)
	_apply_loop_mode(_current_clip)

func set_speed(value: float) -> void:
	_speed = clampf(value, 0.1, 2.0)
	_speed_slider.set_value_no_signal(_speed)
	_speed_label.text = "Speed %.1fx" % _speed

func _apply_loop_mode(name: String) -> void:
	if _animation_player != null and _animation_player.has_animation(name):
		# Manual clock wraps loops; NONE allows an exact seek to the final frame.
		_animation_player.get_animation(name).loop_mode = Animation.LOOP_NONE

func _setup_lip_sync() -> void:
	if _lip_sync != null:
		_lip_sync.free()
	if _audio_player != null:
		_audio_player.free()
	_lip_sync = LipSyncScript.new()
	_audio_player = AudioStreamPlayer.new()
	_audio_player.name = "ReviewLineAudio"
	add_child(_audio_player)
	add_child(_lip_sync)
	_lip_sync.face_mesh_path = _lip_sync.get_path_to(_face_mesh) if _face_mesh != null else NodePath()
	_lip_sync.audio_player_path = _lip_sync.get_path_to(_audio_player)
	if _lip_sync.has_signal("line_finished"):
		_lip_sync.line_finished.connect(_on_line_finished)

func _load_lip_cues(path: String) -> bool:
	if not FileAccess.file_exists(path):
		_set_status("Cue file not found: " + path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var root: Dictionary = parsed
	var raw_cues: Variant = root.get("cues", [])
	if not raw_cues is Array:
		return false
	_lip_cues.clear()
	for raw in raw_cues as Array:
		if raw is Dictionary:
			_lip_cues.append(raw as Dictionary)
	_lip_duration = maxf(float(root.get("duration", 0.0)), 0.0)
	_lip_seek.max_value = maxf(_lip_duration, 0.001)
	_cue_path = path
	_lip_audio = _find_audio_for_cue(path)
	_lip_overlay.set_data(_build_waveform(_lip_audio), _lip_cues, _lip_duration)
	return true

func _find_audio_for_cue(cue_path: String) -> AudioStream:
	var base := cue_path.get_basename()
	for extension in [".wav", ".ogg", ".mp3"]:
		var candidate: String = base + String(extension)
		if FileAccess.file_exists(candidate):
			var stream := _load_audio(candidate)
			if stream != null:
				return stream
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(maxi(1, int(maxf(_lip_duration, 0.1) * 44100.0)) * 2)
	stream.data = bytes
	return stream

func _build_waveform(stream: AudioStream) -> PackedFloat32Array:
	var output := PackedFloat32Array()
	if stream is not AudioStreamWAV or (stream as AudioStreamWAV).format != AudioStreamWAV.FORMAT_16_BITS:
		return output
	output.resize(120)
	var data := (stream as AudioStreamWAV).data
	if data.is_empty():
		return output
	for i in output.size():
		var start := int(float(i) / float(output.size()) * float(data.size() / 2)) * 2
		var end := int(float(i + 1) / float(output.size()) * float(data.size() / 2)) * 2
		var peak := 0.0
		for offset in range(start, mini(end, data.size() - 1), 2):
			var sample := int(data[offset]) | (int(data[offset + 1]) << 8)
			if sample > 32767:
				sample -= 65536
			peak = maxf(peak, absf(float(sample) / 32768.0))
		output[i] = peak
	return output

func attach_prop(prop_path: String, hand: String = "right", place_in_scene: bool = false) -> bool:
	var prop := _instantiate_path(prop_path)
	if prop == null:
		return false
	if place_in_scene:
		_props_container.add_child(prop)
		var hand_position := _bone_world_position(_hand_bone_name(hand))
		prop.global_position = hand_position + _prop_position_offset()
		prop.rotation_degrees = _prop_rotation_offset()
		return true
	if _skeleton == null:
		prop.free()
		return false
	if _attached_attachment != null:
		_attached_attachment.free()
		_attached_attachment = null
		_attached_prop = null
	var bone_name := _hand_bone_name(hand)
	if _skeleton.find_bone(bone_name) < 0:
		prop.free()
		return false
	var attachment := BoneAttachment3D.new()
	attachment.name = "ReviewPropAttachment"
	attachment.bone_name = bone_name
	_skeleton.add_child(attachment)
	attachment.add_child(prop)
	prop.position = _prop_position_offset()
	prop.rotation_degrees = _prop_rotation_offset()
	_attached_attachment = attachment
	_attached_prop = prop
	return true

func clear_props() -> void:
	if is_instance_valid(_attached_attachment):
		_attached_attachment.free()
	_attached_attachment = null
	_attached_prop = null
	for prop in _props_container.get_children():
		prop.free()

func get_attached_prop() -> Node3D:
	return _attached_prop

func _hand_bone_name(hand: String) -> String:
	if _skeleton == null:
		return ""
	var wanted := "RightHand" if hand.to_lower() == "right" else "LeftHand"
	for i in _skeleton.get_bone_count():
		var bone := _skeleton.get_bone_name(i)
		if bone == wanted or bone.ends_with("_" + wanted) or bone.ends_with(":" + wanted):
			return bone
	return wanted

func _prop_position_offset() -> Vector3:
	return Vector3(_prop_x.value, _prop_y.value, _prop_z.value) if _prop_x != null else Vector3.ZERO

func _prop_rotation_offset() -> Vector3:
	return Vector3(_prop_rx.value, _prop_ry.value, _prop_rz.value) if _prop_rx != null else Vector3.ZERO

func _find_bone(names: Array[String]) -> int:
	if _skeleton == null:
		return -1
	for wanted in names:
		var exact := _skeleton.find_bone(wanted)
		if exact >= 0:
			return exact
		for i in _skeleton.get_bone_count():
			var bone := _skeleton.get_bone_name(i)
			if bone.ends_with("_" + wanted) or bone.ends_with(":" + wanted):
				return i
	return -1

func _bone_world_position(name: String) -> Vector3:
	if _skeleton == null:
		return _actor_pivot.global_position
	var index := _find_bone([name])
	if index < 0:
		return _character.global_position
	return (_skeleton.global_transform * _skeleton.get_bone_global_pose(index)).origin

func set_hand_pose(pose: String, side: String = "both") -> bool:
	if _animation_player == null or _skeleton == null:
		return false
	if side not in ["left", "right", "both"]:
		return false
	if pose != "" and pose != "None" and (not HAND_POSES.has(pose) or not _animation_player.has_animation(pose)):
		return false
	_hand_pose_name = pose
	_hand_side = side
	_evaluate_pose()
	return true

func _apply_hand_pose() -> void:
	if _skeleton == null or _hand_pose_name in ["", "None"]:
		return
	var pose := _animation_player.get_animation(_hand_pose_name)
	var animation_root := _animation_player.get_node(_animation_player.root_node)
	for track in pose.get_track_count():
		var path := pose.track_get_path(track)
		if path.get_subname_count() != 1 or animation_root.get_node_or_null(NodePath(path.get_concatenated_names())) != _skeleton:
			continue
		var name := String(path.get_subname(0))
		if not _is_finger_bone(name):
			continue
		if _hand_side == "left" and not name.contains("LeftHand"):
			continue
		if _hand_side == "right" and not name.contains("RightHand"):
			continue
		var bone := _skeleton.find_bone(name)
		if bone < 0 or pose.track_get_key_count(track) == 0:
			continue
		match pose.track_get_type(track):
			Animation.TYPE_ROTATION_3D:
				_skeleton.set_bone_pose_rotation(bone, pose.rotation_track_interpolate(track, 0.0))
			Animation.TYPE_POSITION_3D:
				_skeleton.set_bone_pose_position(bone, pose.position_track_interpolate(track, 0.0))
			Animation.TYPE_SCALE_3D:
				_skeleton.set_bone_pose_scale(bone, pose.scale_track_interpolate(track, 0.0))

func _is_finger_bone(name: String) -> bool:
	return (name.contains("LeftHand") or name.contains("RightHand")) and (name.contains("Thumb") or name.contains("Index") or name.contains("Middle") or name.contains("Ring") or name.contains("Pinky"))

func _set_camera_preset(name: String) -> void:
	_camera_preset = name
	if _camera == null:
		return
	if name == "turntable" or name == "left hand" or name == "right hand" or name == "feet":
		return
	var target := Vector3(0.0, 0.9, 0.0)
	var position := Vector3(0.0, 1.1, 2.8)
	match name:
		"side": position = Vector3(2.8, 1.1, 0.0)
		"back": position = Vector3(0.0, 1.1, -2.8)
		"three-quarter": position = Vector3(2.0, 1.1, 2.0)
		"face close-up":
			position = Vector3(0.0, 1.58, 0.75)
			target = Vector3(0.0, 1.55, 0.0)
	_camera.position = position
	_camera.look_at(target, Vector3.UP)

func _update_camera(delta: float) -> void:
	if _camera == null or _character == null:
		return
	if _camera_preset == "turntable":
		_orbit_angle += delta * 0.45
		var target := _character.global_position + Vector3(0.0, 0.9, 0.0)
		_camera.global_position = target + Vector3(sin(_orbit_angle) * 2.8, 0.25, cos(_orbit_angle) * 2.8)
		_camera.look_at(target, Vector3.UP)
	elif _camera_preset == "left hand" or _camera_preset == "right hand":
		var target := _bone_world_position(_hand_bone_name("left" if _camera_preset == "left hand" else "right"))
		_camera.global_position = target + Vector3(0.65 if _camera_preset == "left hand" else -0.65, 0.25, 0.95)
		_camera.look_at(target, Vector3.UP)
	elif _camera_preset == "feet":
		var target := (_bone_world_position("LeftToeBase") + _bone_world_position("RightToeBase")) * 0.5
		_camera.global_position = target + Vector3(1.2, 0.55, 1.4)
		_camera.look_at(target, Vector3.UP)

func reset_measurements() -> void:
	_foot_slide.reset()
	_measurements = _foot_slide.sample(0.0)

func get_measurements() -> Dictionary:
	return _measurements.duplicate(true)

func _update_measurements() -> void:
	if _measurements.is_empty():
		return
	_measurement_label.text = "m/s: root %.3f | hips %.3f\nankles: L %.3f | R %.3f" % [_measurements.root_speed, _measurements.hip_speed, _measurements.left.foot_speed, _measurements.right.foot_speed]
	var rows: Array[String] = []
	for side in ["left", "right"]:
		var foot: Dictionary = _measurements[side]
		var speed := "%.3f m/s" % foot.slide_speed if foot.contact_samples > 0 else "—"
		rows.append("%s sole %.1f cm | contact slide %s" % [side, foot.height * 100.0, speed])
	_foot_flag_label.text = "Within 2 cm of floor (B03):\n" + "\n".join(rows)

func _update_animation_ui() -> void:
	if _animation_player == null:
		return
	var position := get_current_animation_time()
	var length := get_current_clip_length()
	_scrub.set_block_signals(true)
	_scrub.max_value = maxf(length, 0.001)
	_scrub.set_value_no_signal(position)
	_scrub.set_block_signals(false)
	_time_label.text = "%.2f / %.2f s" % [position, length]
	_play_button.text = "Pause" if _playing else "Play"

func _update_lip_overlay() -> void:
	if _audio_player == null or _lip_overlay == null:
		return
	var time := _audio_player.get_playback_position()
	var current_weights: Dictionary = {}
	if _lip_sync != null and _lip_sync.has_method("get_current_weights"):
		var value: Variant = _lip_sync.call("get_current_weights")
		if value is Dictionary:
			current_weights = value
	elif _lip_sync != null and _lip_sync.has_method("weights_at"):
		var value: Variant = _lip_sync.call("weights_at", time)
		if value is Dictionary:
			current_weights = value
	_lip_overlay.set_playhead(time, current_weights)
	_lip_time_label.text = "%.2f / %.2f s" % [time, _lip_duration]
	_lip_seek.set_value_no_signal(time)

func _configure_capture() -> void:
	if _capture_spec.size() != 3 or not _capture_spec[2].is_valid_float() or _capture_spec[2].to_float() <= 0.0:
		_capture_error("Capture needs --capture=<clip>,<camera>,<positive seconds>")
		return
	if not _clip_names.has(_capture_spec[0]) or not CAMERAS.has(_capture_spec[1]):
		_capture_error("Unknown capture clip or camera: " + ",".join(_capture_spec))
		return
	if Engine.get_write_movie_path().is_empty() or DisplayServer.get_name() == "headless":
		_capture_error("Capture requires --write-movie <output.avi> and a rendering display; omit --headless")
		return
	_set_camera_preset(_capture_spec[1])
	# Authored loops repeat; action clips play once and hold through the recording.
	set_loop(_capture_spec[0].ends_with("_loop"))
	set_one_shot(not _loop_enabled)
	play_clip(_capture_spec[0])
	var fps := Engine.physics_ticks_per_second
	var args := OS.get_cmdline_args()
	var fps_index := args.find("--fixed-fps")
	if fps_index >= 0 and fps_index + 1 < args.size():
		fps = int(args[fps_index + 1])
	else:
		fps = int(ProjectSettings.get_setting("editor/movie_writer/fps", 60))
	_capture_frames_left = maxi(1, int(ceil(_capture_spec[2].to_float() * fps)))
	_capture_skip_advance = true
	_ui_root.hide()
	_viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	RenderingServer.frame_post_draw.connect(_capture_frame_drawn)
	print("CAPTURE start clip=%s camera=%s frames=%d fps=%d output=%s" % [_current_clip, _camera_preset, _capture_frames_left, fps, Engine.get_write_movie_path()])

func _capture_error(message: String) -> void:
	push_error(message)
	get_tree().quit(2)

func _open_file_dialog(kind: String) -> void:
	_file_kind = kind
	_file_dialog.popup_centered_ratio(0.7)

func _on_file_selected(path: String) -> void:
	if _file_kind == "cue":
		_load_lip_cues(path)
	else:
		var stream := _load_audio(path)
		if stream != null:
			_lip_audio = stream
			_lip_overlay.set_data(_build_waveform(stream), _lip_cues, _lip_duration)

func _on_character_selected(index: int) -> void:
	load_character(String(_character_option.get_item_metadata(index)))

func _on_clip_selected(index: int) -> void:
	if index >= 0 and index < _clip_names.size():
		select_clip(_clip_names[index])

func _on_camera_selected(index: int) -> void:
	_set_camera_preset(_camera_option.get_item_text(index))

func _on_play_pressed() -> void:
	if _animation_player != null and _playing:
		pause_clip()
	else:
		play_clip()

func _on_scrub_changed(value: float) -> void:
	seek_animation(value)

func _on_speed_changed(value: float) -> void:
	set_speed(value)

func _on_loop_toggled(value: bool) -> void:
	set_loop(value)

func _on_one_shot_toggled(value: bool) -> void:
	set_one_shot(value)

func _on_hand_pose_selected(index: int) -> void:
	set_hand_pose(_hand_option.get_item_text(index), _hand_side)

func _on_hand_side_selected(index: int) -> void:
	set_hand_pose(_hand_pose_name, _hand_side_option.get_item_text(index))

func _on_debug_toggled(_value: bool) -> void:
	_refresh_debug_draw()

func _refresh_debug_draw() -> void:
	if _unshaded_check != null and _unshaded_check.button_pressed:
		_review_viewport.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
	elif _wireframe_check != null and _wireframe_check.button_pressed:
		_review_viewport.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	else:
		_review_viewport.debug_draw = Viewport.DEBUG_DRAW_DISABLED

func _attach_selected_prop(hand: String) -> void:
	var index := _prop_option.selected
	if index >= 0:
		attach_prop(String(_prop_option.get_item_metadata(index)), hand, false)

func _place_selected_prop() -> void:
	var index := _prop_option.selected
	if index >= 0:
		attach_prop(String(_prop_option.get_item_metadata(index)), "right", true)

func _on_lip_play_pressed() -> void:
	if _lip_sync == null or not _lip_sync.has_method("play_line"):
		return
	_lip_audio = _lip_audio if _lip_audio != null else _find_audio_for_cue(_cue_path)
	_lip_sync.call("play_line", _lip_audio, _cue_path)
	_lip_play_button.text = "Playing line"

func _on_lip_pause_pressed() -> void:
	if _lip_sync == null or _audio_player == null:
		return
	if _audio_player.stream_paused:
		_lip_sync.resume()
	else:
		_lip_sync.pause()

func _on_lip_seek_changed(value: float) -> void:
	if _lip_sync != null:
		_lip_sync.seek(value)
		_lip_overlay.set_playhead(value, _lip_sync.get_current_weights())

func _on_line_finished() -> void:
	_lip_play_button.text = "Play line"

func _set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text

func _process(delta: float) -> void:
	if _capture_skip_advance:
		_capture_skip_advance = false
	else:
		advance_playback(delta)
	_update_camera(delta)
	_update_animation_ui()
	_update_measurements()
	_update_lip_overlay()
	_update_bone_lines()

func _capture_frame_drawn() -> void:
	_capture_frames_left -= 1
	_capture_frames_written += 1
	if _capture_frames_left == 0:
		RenderingServer.frame_post_draw.disconnect(_capture_frame_drawn)
		print("CAPTURE complete: %d rendered frames" % _capture_frames_written)
		get_tree().quit(0)

func _add_props_from(directory: String) -> void:
	for folder in DirAccess.get_directories_at(directory):
		var path := directory.path_join(folder).path_join(folder + ".glb")
		if FileAccess.file_exists(path):
			_prop_option.add_item(folder)
			_prop_option.set_item_metadata(_prop_option.item_count - 1, path)

func _on_prop_offset_changed(_value: float) -> void:
	if is_instance_valid(_attached_prop):
		_attached_prop.position = _prop_position_offset()
		_attached_prop.rotation_degrees = _prop_rotation_offset()

func _load_audio(path: String) -> AudioStream:
	match path.get_extension().to_lower():
		"wav": return AudioStreamWAV.load_from_file(path)
		"ogg": return AudioStreamOggVorbis.load_from_file(path)
		"mp3": return AudioStreamMP3.load_from_file(path)
	return null

# Viewports have no skeleton debug mode: draw each bone as a line to its parent, on top of the mesh.
func _update_bone_lines() -> void:
	var show := _skeleton_check != null and _skeleton_check.button_pressed and _skeleton != null
	if _bone_lines == null:
		if not show:
			return
		_bone_lines = MeshInstance3D.new()
		_bone_lines.mesh = ImmediateMesh.new()
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.no_depth_test = true
		material.albedo_color = Color(1.0, 0.8, 0.1)
		_bone_lines.material_override = material
		_stage.add_child(_bone_lines)
	_bone_lines.visible = show
	if not show:
		return
	var mesh := _bone_lines.mesh as ImmediateMesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var to_world := _skeleton.global_transform
	for bone in _skeleton.get_bone_count():
		var parent := _skeleton.get_bone_parent(bone)
		if parent < 0:
			continue
		mesh.surface_add_vertex(to_world * _skeleton.get_bone_global_pose(parent).origin)
		mesh.surface_add_vertex(to_world * _skeleton.get_bone_global_pose(bone).origin)
	mesh.surface_end()
