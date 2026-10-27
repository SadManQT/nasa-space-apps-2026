# Godot --headless --path game -s tools/test_asset_showcase.gd
extends SceneTree

const Showcase: PackedScene = preload("res://scenes/dev/asset_showcase.tscn")
const CATEGORIES: Array[String] = ["characters", "plants", "props", "vehicles", "environment"]
const HANDLE_RADIUS: float = 0.033   # PR_HandLight barrel, measured on the mesh

var _level: Node3D
var _checks: int = 0
var _failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_level = Showcase.instantiate()
	root.add_child(_level)
	await process_frame
	if not _check(_level.get("exhibits") != null and _level.player.animation != null, "showcase and player load"):
		_level.free()
		quit(1)
		return
	_test_inventory()
	_test_bounds()
	_test_cutscene_list()
	await _test_modal_input()
	await _test_switching_and_holds()
	_test_bounds()
	_level.free()
	await process_frame
	print("SHOWCASE RESULT: %s (%d checks, %d failures)" % ["PASS" if _failures == 0 else "FAIL", _checks, _failures])
	quit(0 if _failures == 0 else 1)

func _files(directory: String, extension: String) -> PackedStringArray:
	var result := PackedStringArray()
	if not DirAccess.dir_exists_absolute(directory):
		return result
	for file in DirAccess.get_files_at(directory):
		if file.get_extension().to_lower() == extension:
			result.append(directory.path_join(file))
	for folder in DirAccess.get_directories_at(directory):
		result.append_array(_files(directory.path_join(folder), extension))
	result.sort()
	return result

func _test_inventory() -> void:
	var expected := PackedStringArray()
	for category in CATEGORIES:
		expected.append_array(_files("res://assets/" + category, "glb"))
	var placed := PackedStringArray()
	for entry in _level.exhibits:
		placed.append(entry.path)
		var label: Label3D = entry.label
		_check(label != null and label.text == _level.display_name(entry.model.name) + "\n" + String(entry.category).capitalize(), "label " + entry.model.name)
		var plinth_front: float = entry.plinth.position.z + entry.size.z * 0.5
		_check(label.font_size * label.pixel_size >= 0.13 and label.position.y < entry.plinth_top + 0.2 and label.position.z > plinth_front - 0.2, "readable placard on plinth front " + entry.model.name)
		if entry.category == "characters":
			_check(entry.model.get_node_or_null("FaceAtlas") != null and entry.model.get_node_or_null("HairSprings") != null, "face and hair " + entry.model.name)
		var meshes: Array[Node] = entry.model.find_children("*", "MeshInstance3D", true, false)
		var styled := false
		for mesh in meshes:
			var material: Material = mesh.get_active_material(0)
			if material is ShaderMaterial and material.shader in [ToonMaterials.CHARACTER_SHADER, ToonMaterials.WORLD_SHADER]:
				styled = true
		_check(styled, "toon material " + entry.model.name)
	expected.sort()
	placed.sort()
	_check(expected == placed, "every GLB has exactly one catalog exhibit (%d)" % expected.size())
	_check(_level.display_name("PR_BatteryJar") == "Battery Jar", "camel case name without prefix")
	for actor in _level._cast:
		var motion: PlayerAnimation = actor.motion
		_check(motion.player.has_animation("motion/Idle_loop") and not motion.idle_variations, "idle loop " + actor.model.name)
		if actor.model.name in ["CH_Kai", "CH_Rafi"]:
			var hold := PlayerAnimation.Hold.BOX if actor.model.name == "CH_Kai" else PlayerAnimation.Hold.RIGHT
			_check(motion.hold_mode == hold and actor.attachment.prop != null, "showcase hold " + actor.model.name)

func _test_bounds() -> void:
	var boxes: Array[AABB] = []
	var names: Array[String] = []
	for entry in _level.exhibits:
		var model: Node3D = entry.model
		var box := model.global_transform * AssetGeometry.bounds(model, entry.category == "characters")
		var plinth: StaticBody3D = entry.plinth
		var shape := (plinth.get_child(0) as CollisionShape3D).shape as BoxShape3D
		var top := plinth.global_position.y + shape.size.y * 0.5
		_check(absf(box.position.y - top) <= 0.01, "%s grounded (%.4f m)" % [model.name, box.position.y - top])
		boxes.append(box)
		names.append(model.name)
	var overlaps := PackedStringArray()
	for a in boxes.size():
		for b in range(a + 1, boxes.size()):
			if boxes[a].intersects(boxes[b]):
				overlaps.append(names[a] + " / " + names[b])
	_check(overlaps.is_empty(), "all exhibit AABBs disjoint: " + ", ".join(overlaps))

func _test_cutscene_list() -> void:
	var expected := _files("res://assets/cutscenes", "ogv")
	_check(_level.cutscene_files == expected and _level.cutscene_buttons.size() == expected.size(), "panel lists installed OGV files")
	var directory := OS.get_environment("TMPDIR").path_join("showcase_test_%d" % Time.get_ticks_usec())
	_check(DirAccess.make_dir_recursive_absolute(directory) == OK, "temporary video listing fixture")
	_level.refresh_cutscenes(directory)
	_check(_level.cutscene_buttons.is_empty() and _level._cutscene_list.get_child(0).text == "No cutscenes yet", "empty cutscene folder")
	var files: Array[String] = ["CS-02_Garden.ogv", "CS-01_Arrival.ogv", "README.md", "CS-03_Night.OGV"]
	for name in files:
		var file := FileAccess.open(directory.path_join(name), FileAccess.WRITE)
		_check(file != null, "create listing fixture " + name)
		if file != null:
			file.close()
	_level.refresh_cutscenes(directory)
	_check(_level.cutscene_files == _files(directory, "ogv") and _level.cutscene_buttons.size() == 3, "sorted OGV discovery ignores other files")
	_check(_level.cutscene_buttons[0].text == "CS-01 Arrival", "cutscene button readable title")
	_check(_level.cutscene_buttons[0].pressed.is_connected(_level.play_cutscene.bind(directory.path_join(files[1]))), "button launches its own video")
	for name in files:
		DirAccess.remove_absolute(directory.path_join(name))
	DirAccess.remove_absolute(directory)
	_level.refresh_cutscenes(directory)
	_check(_level.cutscene_buttons.is_empty(), "missing cutscene folder")
	_level.refresh_cutscenes()

func _key(code: Key, pressed: bool = true) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	root.push_input(event)

func _test_modal_input() -> void:
	_key(KEY_C)
	_check(_level.panel.visible and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "C opens panel with visible mouse")
	var player: PlayerController = _level.player
	var before := player.global_transform
	var yaw := player.follow_camera.yaw
	Input.action_press("move_forward")
	_key(KEY_TAB)
	_key(KEY_H)
	var mouse := InputEventMouseMotion.new()
	mouse.screen_relative = Vector2(120.0, 50.0)
	root.push_input(mouse)
	for frame in 4:
		await physics_frame
		await process_frame
	Input.action_release("move_forward")
	_check(player == _level.player and player.global_transform == before and player.follow_camera.yaw == yaw and player.animation.hold_mode == PlayerAnimation.Hold.NONE, "panel blocks walking, camera, swapping and holds")
	var button := Button.new()
	button.text = "Keyboard activation probe"
	button.pressed.connect(func() -> void: button.set_meta("activated", true))
	_level._cutscene_list.add_child(button)
	button.grab_focus()
	_key(KEY_ENTER)
	_key(KEY_ENTER, false)
	_check(button.get_meta("activated", false), "panel buttons accept keyboard activation")
	button.free()
	_level.video_overlay.show()
	_level.panel.hide()
	_key(KEY_SPACE)
	_check(_level.video.paused, "Space pauses video")
	_key(KEY_SPACE)
	_check(not _level.video.paused, "Space resumes video")
	_key(KEY_TAB)
	_check(player == _level.player and player.process_mode == Node.PROCESS_MODE_DISABLED, "video blocks player input")
	_key(KEY_ESCAPE)
	_check(not _level.video_overlay.visible and _level.panel.visible and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Esc returns video to panel")
	_check(_level.video.finished.is_connected(_level.close_video), "video completion returns to panel")
	_key(KEY_ESCAPE)
	_check(not _level.panel.visible and player.process_mode == Node.PROCESS_MODE_INHERIT, "Esc closes panel and restores player")
	_check(_level._video_frame.stretch_mode == AspectRatioContainer.STRETCH_FIT and _level.video_overlay.color == Color.BLACK, "video fits aspect ratio on black")

func _test_switching_and_holds() -> void:
	_level.player.set_hold(PlayerAnimation.Hold.BOX)
	for index in 5:
		var old: PlayerController = _level.player
		var spot := old.global_position
		var facing := old.visual.global_rotation.y
		var yaw := old.follow_camera.yaw
		var pitch := old.follow_camera.pitch
		var camera_transform := old.follow_camera.camera.global_transform
		_key((KEY_1 + index) as Key)
		var player: PlayerController = _level.player
		_check(player != old and player.loaded_path.ends_with(_level.CAST[index] + ".glb"), "number key switches " + _level.CAST[index])
		_check(player.global_position.distance_to(spot) < 0.01 and absf(angle_difference(player.visual.global_rotation.y, facing)) < 0.01, "switch preserves position and facing")
		_check(is_equal_approx(player.follow_camera.yaw, yaw) and is_equal_approx(player.follow_camera.pitch, pitch), "switch preserves camera")
		_check(player.follow_camera.camera.global_transform.is_equal_approx(camera_transform), "switch preserves actual camera transform without a frame jump")
		_check(player.animation.hold_mode == PlayerAnimation.Hold.BOX, "switch preserves hold")
		player.set_physics_process(false)
		player.look_at_enabled = false
		player.lean_enabled = false
		for mode in [PlayerAnimation.Hold.BOX, PlayerAnimation.Hold.RIGHT]:
			player.set_hold(mode)
			_level._sync_player_hold()
			var attachment: HeldProp = _level.player_prop
			_check(attachment.prop != null and attachment.prop_bounds.has_volume(), "held prop has geometry")
			player.animation.advance(0.3, 0.0)
			var samples: Array[Vector2] = []
			var probe := _measure_hold.bind(attachment, player, samples)
			player.animation.skeleton.skeleton_updated.connect(probe)
			for frame in 12:
				player.visual.rotation.y += 0.03
				player.animation.advance(1.0 / 30.0, player.tuning.walk_speed if frame > 5 else 0.0)
				player.animation.skeleton.advance(1.0 / 30.0)
				await process_frame
			player.animation.skeleton.skeleton_updated.disconnect(probe)
			var error := 0.0
			var orientation_error := 0.0
			for sample in samples:
				error = maxf(error, sample.x)
				orientation_error = maxf(orientation_error, sample.y)
			_check(samples.size() >= 12, "attachment sampled after final skeleton modifiers")
			_check(error <= 0.02, "%s %s palm contact <= 2 cm (%.5f m)" % [_level.CAST[index], PlayerAnimation.Hold.keys()[mode], error])
			_check(orientation_error < 0.001, "prop follows body / hand orientation while turning and walking")
		player.set_hold(PlayerAnimation.Hold.NONE)
		_level._sync_player_hold()
		_check(_level.player_prop.prop == null, "NONE removes held prop")
		_key(KEY_H)
		_check(player.animation.hold_mode == PlayerAnimation.Hold.BOX and _level.player_prop.prop != null, "H equips box")
		_key(KEY_H)
		_check(player.animation.hold_mode == PlayerAnimation.Hold.RIGHT and _level.player_prop.prop != null, "H equips light")
		_key(KEY_H)
		_check(player.animation.hold_mode == PlayerAnimation.Hold.NONE and _level.player_prop.prop == null, "H clears hold")
		player.set_hold(PlayerAnimation.Hold.BOX)
		await process_frame
	_key(KEY_TAB)
	_check(_level.cast_index == 0 and _level.player.loaded_path.ends_with("CH_Kai.glb"), "Tab wraps Ferreira to Kai")

func _measure_hold(attachment: HeldProp, player: PlayerController, samples: Array[Vector2]) -> void:
	var rig := player.animation.skeleton
	var right := _palm(rig, "Right")
	var prop := attachment.prop
	var error := 0.0
	var orientation_error := 0.0
	var bounds := AssetGeometry.bounds(prop)
	if attachment.mode == PlayerAnimation.Hold.BOX:
		var left := _palm(rig, "Left")
		var low := left if prop.to_local(left).x < prop.to_local(right).x else right
		var high := right if low == left else left
		for side in 2:
			var palm := low if side == 0 else high
			var point := prop.to_local(palm).clamp(bounds.position, bounds.end)
			point.x = bounds.position.x if side == 0 else bounds.end.x
			error = maxf(error, palm.distance_to(prop.to_global(point)))
		orientation_error = 1.0 - prop.global_basis.x.normalized().dot(player.visual.global_basis.x.normalized())
	else:
		# Power grip: the palm rests on the handle (a palm's half thickness plus the 3.3 cm barrel radius from its
		# axis), the palm is over the grip, and the handle runs across the palm from the pinky to the index side.
		var axis := prop.global_basis.x.normalized()
		var offset := right - prop.to_global(attachment.grip)
		var radial := (offset - axis * offset.dot(axis)).length()
		error = maxf(absf(radial - (HANDLE_RADIUS + HeldProp.PALM_HALF_THICKNESS)), absf(offset.dot(axis)) - 0.04)
		orientation_error = 1.0 - axis.dot((_bone(rig, "RightHandIndex1") - _bone(rig, "RightHandPinky1")).normalized())
	samples.append(Vector2(error, orientation_error))

func _bone(rig: Skeleton3D, suffix: String) -> Vector3:
	return rig.global_transform * rig.get_bone_global_pose(rig.find_bone("mixamorig_" + suffix)).origin

func _palm(rig: Skeleton3D, side: String) -> Vector3:
	return (_bone(rig, side + "Hand") + _bone(rig, side + "HandMiddle1")) * 0.5

func _check(condition: bool, message: String) -> bool:
	_checks += 1
	if condition:
		print("  ok ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
	return condition
