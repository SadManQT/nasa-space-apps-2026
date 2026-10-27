# Headless regression and runtime GLTF integration checks for the v4 face layers.
#   Godot --headless --path game --script res://tools/test_face_expression.gd
# Optional fixture override: -- --character=/absolute/path/to/CH_Kai.glb
extends SceneTree

const LipSyncScript: Script = preload("res://scripts/lip_sync.gd")
const FaceScript: Script = preload("res://scripts/face_expression.gd")
const HeadScript: Script = preload("res://scripts/head_accent.gd")
const KAI_PATH: String = "/private/tmp/claude-501/-Users-sadmansakib-nasa-space-apps-2026/8b783e13-4d3f-4549-8fec-ee82b9a2d7f4/scratchpad/v4/CH_Kai/CH_Kai.glb"

# A controllable source for unit tests; the integration check uses real LipSync.
class EnvelopeSource extends LipSync:
	var envelope: float = 0.0
	func get_current_envelope() -> float:
		return envelope

var _failed := false
var _checks: int = 0
var _fixtures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_expressions()
	_test_blinks()
	_test_composition()
	_test_missing_shapes()
	await _test_head_accent()
	await _test_process_order()
	await _test_character()
	for path in _fixtures:
		DirAccess.remove_absolute(path)
	# Let the dummy audio driver's next mix release stopped playback objects.
	await create_timer(0.1).timeout
	if _failed:
		print("FAIL FaceExpression / HeadAccent (%d checks)" % _checks)
		quit(1)
		return
	print("PASS FaceExpression / HeadAccent (%d checks, including runtime Kai GLTF integration)" % _checks)
	quit(0)

func _test_expressions() -> void:
	var rig := _make_rig(FaceScript.SHAPE_NAMES)
	var face = rig.face
	var mesh: MeshInstance3D = rig.mesh
	face.blink_enabled = false
	for shape in ["exprNeutral", "exprSerious", "browUp", "browDown"]:
		face.set_expression(shape, 0.8, 0.4)
		face._process(0.1)
		_check(_near(_weight(mesh, shape), 0.2), shape + " fade at quarter duration")
		face._process(0.3)
		_check(_near(_weight(mesh, shape), 0.8), shape + " reaches target on time")
		face.set_expression(shape, 0.0, 0.2)
		face._process(0.1)
		_check(_near(_weight(mesh, shape), 0.4), shape + " fades down from current weight")
		face._process(0.1)
		_check(_near(_weight(mesh, shape), 0.0), shape + " returns to rest")
	face.set_expression("exprSerious", 1.0, 1.0)
	face._process(0.4)
	face.set_expression("exprSerious", 0.0, 0.2)
	face._process(0.1)
	_check(_near(_weight(mesh, "exprSerious"), 0.2), "retargeting a fade stays continuous")
	face.set_expression("browUp", 3.0, 0.0)
	face.set_expression("browDown", -1.0, -1.0)
	face.set_expression("unknown", 1.0, 0.0)
	face._process(0.0)
	_check(_near(_weight(mesh, "browUp"), 1.0) and _near(_weight(mesh, "browDown"), 0.0), "immediate values clamp and unknown expressions are skipped")
	face.set_expression("eyesBlink", 1.0, 0.0)
	face._process(0.0)
	_check(_near(_weight(mesh, "eyesBlink"), 1.0), "manual closure works with automatic blinks disabled")
	rig.root.free()

func _test_blinks() -> void:
	var rig := _make_rig(FaceScript.SHAPE_NAMES)
	var face = rig.face
	var mesh: MeshInstance3D = rig.mesh
	face._rng.seed = 90210
	var gaps: Array[float] = []
	for i in 200:
		face._schedule_blink()
		gaps.append(face._blink_timer)
	_check(gaps.all(func(g): return g >= 2.0 and g <= 6.0) and gaps.max() - gaps.min() > 3.0, "blink gaps are random within 2-6 seconds")
	face._blink_timer = 2.0
	face._process(1.999)
	_check(_near(_weight(mesh, "eyesBlink"), 0.0), "eyes stay open before scheduled blink")
	face._process(0.041)
	_check(_near(_weight(mesh, "eyesBlink"), 1.0), "blink reaches full closure at 40 ms")
	face._blink_double = false
	face._process(0.02)
	_check(_near(_weight(mesh, "eyesBlink"), 1.0), "blink holds full closure through 60 ms")
	face._process(0.03)
	_check(_near(_weight(mesh, "eyesBlink"), 0.5), "blink opens smoothly")
	face._process(0.03)
	_check(_near(_weight(mesh, "eyesBlink"), 0.0) and face._blink_phase == FaceScript.BlinkPhase.WAIT, "blink finishes at 120 ms and reschedules")

	# Force the branch that previously produced an endless double-blink loop.
	face._blink_timer = 0.0
	face._process(0.04)
	face._blink_double = true
	face._process(0.08)
	_check(face._blink_phase == FaceScript.BlinkPhase.DOUBLE_GAP and _near(_weight(mesh, "eyesBlink"), 0.0), "double blink has an open inter-blink gap")
	face._process(0.12)
	_check(_near(_weight(mesh, "eyesBlink"), 1.0), "second blink closes after its 80 ms gap")
	face._process(0.08)
	_check(face._blink_phase == FaceScript.BlinkPhase.WAIT and not face._blink_double and _near(_weight(mesh, "eyesBlink"), 0.0), "double blink ends after exactly two blinks")
	var doubles := 0
	face._rng.seed = 123456
	for i in 2000:
		face._blink_timer = 0.0
		face._update_blink(0.001)
		if face._blink_double:
			doubles += 1
		face._update_blink(0.4)
	_check(absf(float(doubles) / 2000.0 - 0.15) < 0.03, "double-blink probability near 15 percent (got %d / 2000)" % doubles)
	face._blink_timer = 0.0
	face._process(0.04)
	face.blink_enabled = false
	face._process(0.0)
	_check(_near(_weight(mesh, "eyesBlink"), 0.0), "disabling blinks reopens the eyes immediately")
	face.blink_enabled = true
	for fps in [30, 60, 120]:
		face._blink_timer = 0.0
		var peak := 0.0
		for i in 24:
			face._process(1.0 / float(fps))
			face._blink_double = false
			peak = maxf(peak, _weight(mesh, "eyesBlink"))
		_check(peak >= 0.88 and face._blink_phase == FaceScript.BlinkPhase.WAIT, "blink stays brief with visible closure at %d fps" % fps)
		face.blink_enabled = false
		face._process(0.0)
		face.blink_enabled = true
	rig.root.free()

func _test_composition() -> void:
	var rig := _make_rig(FaceScript.SHAPE_NAMES)
	var face = rig.face
	var lip = rig.lip
	var mesh: MeshInstance3D = rig.mesh
	face.blink_enabled = false
	lip.play_line(_silent_stream(), _cue_file("composition", [[0.0, "viseme_aa", 0.6], [0.12, "browUp", 0.3]]))
	lip.seek(0.11)
	face.set_expression("exprSerious", 0.7, 0.0)
	face.set_expression("browUp", 0.4, 0.0)
	face._process(0.0)
	_check(_near(_weight(mesh, "viseme_aa"), 0.6) and _near(_weight(mesh, "exprSerious"), 0.7), "speech and expression both reach the mesh")
	_check(_near(_weight(mesh, "browUp"), 0.7), "overlapping shape sums speech 0.3 + expression 0.4")
	face.set_expression("browUp", 0.9, 0.0)
	face._process(0.0)
	_check(_near(_weight(mesh, "browUp"), 1.0), "combined weights clamp at 1")
	lip.seek(0.2)
	_check(_near(_weight(mesh, "browUp"), 1.0), "LipSync does not overwrite the mixer's result")
	lip.stop(true)
	face._process(0.0)
	_check(_near(_weight(mesh, "viseme_aa"), 0.0) and _near(_weight(mesh, "exprSerious"), 0.7), "stopping speech preserves expression")
	lip.play_line(_silent_stream(), _cue_file("handoff", [[0.0, "viseme_aa", 0.5]]))
	lip.seek(0.1)
	face._process(0.0)
	face.free()
	_check(lip._mixer == null and _near(_weight(mesh, "exprSerious"), 0.0) and _near(_weight(mesh, "viseme_aa"), 0.5), "removing FaceExpression restores standalone LipSync")
	lip.stop(true)
	_check(_near(_weight(mesh, "viseme_aa"), 0.0), "standalone LipSync writes again after mixer removal")
	rig.root.free()

func _test_missing_shapes() -> void:
	var rig := _make_rig(["exprSerious", "viseme_aa"])
	rig.face.set_expression("browUp", 1.0, 0.0)
	rig.face.set_expression("exprSerious", 0.6, 0.0)
	rig.face._process(10.0)
	_check(rig.face._blend_indices.size() == 2 and _near(_weight(rig.mesh, "exprSerious"), 0.6), "partial mesh skips absent expressions, visemes and eyelids")
	rig.root.free()
	rig = _make_rig([])
	rig.face._process(10.0)
	_check(rig.face._blend_indices.is_empty(), "mesh with no blend shapes is harmless")
	rig.root.free()
	var missing = FaceScript.new()
	get_root().add_child(missing)
	missing._process(10.0)
	_check(missing._blend_indices.is_empty(), "missing mesh and LipSync are harmless")
	missing.free()
	rig = _make_rig(FaceScript.SHAPE_NAMES)
	rig.lip.free()
	rig.face.set_expression("exprNeutral", 0.4, 0.0)
	rig.face._process(0.0)
	_check(_near(_weight(rig.mesh, "exprNeutral"), 0.4), "freed speech source leaves expressions working")
	rig.root.free()

func _test_head_accent() -> void:
	var container := Node3D.new()
	var source := EnvelopeSource.new()
	source.name = "LipSync"
	container.add_child(source)
	var skeleton := Skeleton3D.new()
	container.add_child(skeleton)
	skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	skeleton.add_bone("mixamorig_Neck")
	skeleton.add_bone("mixamorig_Head")
	skeleton.set_bone_parent(1, 0)
	var base := Quaternion(Vector3.UP, 0.3)
	skeleton.set_bone_pose_rotation(1, base)
	var head = HeadScript.new()
	head.lip_sync_path = NodePath("../../LipSync")
	skeleton.add_child(head)
	get_root().add_child(container)
	var observed := {"head": base, "neck": Quaternion.IDENTITY}
	head.modification_processed.connect(func():
		if skeleton.get_bone_count() < 2:
			return
		observed.head = skeleton.get_bone_pose_rotation(1)
		observed.neck = skeleton.get_bone_pose_rotation(0))
	source.envelope = 1.0
	skeleton.advance(0.016)
	await process_frame
	_check(not head.enabled and not head.active and _angle(base, observed.head) < 0.001, "head accent is off by default")
	head.enabled = true
	skeleton.advance(0.1)
	await process_frame
	_check(_angle(base, observed.head) < 0.001, "enabling on constant loudness does not invent an onset")
	source.envelope = 0.0
	skeleton.advance(0.05)
	await process_frame
	source.envelope = 1.0
	skeleton.advance(0.016)
	await process_frame
	var first_angle := _angle(base, observed.head)
	_check(first_angle > 0.1 and first_angle < 2.0 and _angle(Quaternion.IDENTITY, observed.neck) > 0.01, "loudness onset produces a smoothed head nod and smaller neck accent")
	var maximum := 0.0
	for i in 600:
		source.envelope = 1.0 if i % 30 >= 15 else 0.0
		skeleton.advance(1.0 / 60.0)
		await process_frame
		maximum = maxf(maximum, _angle(base, observed.head) + _angle(Quaternion.IDENTITY, observed.neck))
	_check(maximum > 0.5 and maximum <= 4.01, "repeated onsets stay within 4 degrees total (max %.3f)" % maximum)
	_check(_angle(base, skeleton.get_bone_pose_rotation(1)) < 0.001, "modifier stack restores animated input pose without accumulation")
	source.envelope = 1.0
	for i in 180:
		skeleton.advance(1.0 / 60.0)
		await process_frame
	_check(_angle(base, observed.head) < 0.01, "sustained loudness settles without retriggering")
	# Runtime settings are clamped even if assigned outside inspector ranges.
	head.max_angle_degrees = 100.0
	head.neck_share = 5.0
	for i in 120:
		source.envelope = 1.0 if i % 20 >= 10 else 0.0
		skeleton.advance(1.0 / 60.0)
		await process_frame
		maximum = maxf(maximum, _angle(base, observed.head) + _angle(Quaternion.IDENTITY, observed.neck))
	_check(maximum <= 4.01, "out-of-range settings cannot exceed the hard rotation cap")
	head.enabled = false
	skeleton.advance(0.1)
	await process_frame
	_check(_angle(base, skeleton.get_bone_pose_rotation(1)) < 0.001 and head._offset == Vector2.ZERO, "disabling removes the accent and resets its state")
	head.enabled = true
	skeleton.clear_bones()
	skeleton.advance(0.1)
	await process_frame
	_check(head._head_index == -1 and head._neck_index == -1, "missing head and neck bones are skipped")
	container.free()

func _test_process_order() -> void:
	# Face is deliberately earlier in sibling order than LipSync.
	var rig := _make_rig(FaceScript.SHAPE_NAMES)
	rig.face.blink_enabled = false
	rig.face.set_expression("exprSerious", 0.8, 0.0)
	rig.face.set_process(true)
	rig.lip.play_line(_silent_stream(), _cue_file("order", [[0.0, "viseme_aa", 1.0]]))
	rig.lip.seek(0.1)
	rig.lip.pause()
	rig.lip.stop(false)
	await process_frame
	await process_frame
	var speech: Dictionary = rig.lip.get_current_weights()
	_check(rig.face.process_priority > rig.lip.process_priority and _near(_weight(rig.mesh, "viseme_aa"), speech["viseme_aa"]), "real scene processing composes current-frame speech despite sibling order")
	_check(_near(_weight(rig.mesh, "exprSerious"), 0.8), "real scene processing preserves expression during speech release")
	rig.root.free()

func _test_character() -> void:
	var path := KAI_PATH
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--character="):
			path = argument.trim_prefix("--character=")
	_check(FileAccess.file_exists(path), "Kai GLB fixture exists")
	if not FileAccess.file_exists(path):
		return
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file(path, state)
	_check(error == OK, "GLTFDocument loads Kai at runtime (error %d)" % error)
	if error != OK:
		return
	var character := document.generate_scene(state)
	_check(character != null, "GLTFDocument generates Kai scene")
	if character == null:
		return
	var mesh := _find_face(character)
	var skeleton := _find_skeleton(character)
	_check(mesh != null and mesh.mesh.get_blend_shape_count() == 21, "Kai face has all 21 blend shapes")
	_check(skeleton != null and skeleton.get_bone_count() == 65, "Kai skeleton has 65 bones")
	if mesh == null or skeleton == null:
		character.free()
		return
	print("  integration mesh: ", character.get_path_to(mesh))
	print("  integration skeleton: ", character.get_path_to(skeleton))
	var lip = LipSyncScript.new()
	lip.name = "LipSync"
	character.add_child(lip)
	lip.face_mesh_path = lip.get_path_to(mesh)
	var audio := AudioStreamPlayer.new()
	audio.name = "Voice"
	lip.add_child(audio)
	lip.audio_player_path = NodePath("Voice")
	var face = FaceScript.new()
	face.name = "FaceExpression"
	character.add_child(face)
	face.face_mesh_path = face.get_path_to(mesh)
	face.lip_sync_path = face.get_path_to(lip)
	var head = HeadScript.new()
	skeleton.add_child(head)
	head.lip_sync_path = head.get_path_to(lip)
	skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	get_root().add_child(character)
	face.set_process(false)
	face.blink_enabled = false
	lip.play_line(_silent_stream(), _cue_file("kai", [[0.0, "viseme_aa", 0.8]], [0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0]))
	lip.set_process(false)
	lip.seek(0.02)
	head.enabled = true
	skeleton.advance(0.02)
	await process_frame
	lip.seek(0.06)
	for shape in ["exprNeutral", "exprSerious", "browUp", "browDown"]:
		face.set_expression(shape, 0.4, 0.0)
	face._process(0.0)
	_check(_near(_weight(mesh, "viseme_aa"), 0.8), "Kai MeshInstance3D receives real LipSync speech")
	_check(["exprNeutral", "exprSerious", "browUp", "browDown"].all(func(shape): return _near(_weight(mesh, shape), 0.4)), "Kai MeshInstance3D receives all four expressions alongside speech")
	face.blink_enabled = true
	face._blink_timer = 0.0
	face._process(0.04)
	_check(_near(_weight(mesh, "eyesBlink"), 1.0) and _near(_weight(mesh, "viseme_aa"), 0.8), "Kai blink closes while its speaking mouth stays driven")
	var head_bone := skeleton.find_bone("mixamorig_Head")
	var neck_bone := skeleton.find_bone("mixamorig_Neck")
	_check(head_bone >= 0 and neck_bone >= 0, "Kai Mixamo head and neck names resolve")
	if head_bone >= 0 and neck_bone >= 0:
		var base := skeleton.get_bone_pose_rotation(head_bone)
		var measured := {"angle": 0.0}
		head.modification_processed.connect(func(): measured.angle = _angle(base, skeleton.get_bone_pose_rotation(head_bone)))
		skeleton.advance(0.05)
		await process_frame
		_check(measured.angle > 0.1 and measured.angle <= 4.01, "Kai head modifier responds to real LipSync envelope (%.3f degrees)" % measured.angle)
	character.free()
	await process_frame

func _make_rig(shapes: Array) -> Dictionary:
	var container := Node.new()
	var mesh := MeshInstance3D.new()
	mesh.name = "FaceMesh"
	mesh.mesh = _test_mesh(shapes)
	container.add_child(mesh)
	var face = FaceScript.new()
	face.name = "Expression"
	face.face_mesh_path = NodePath("../FaceMesh")
	face.lip_sync_path = NodePath("../LipSync")
	container.add_child(face)
	var lip = LipSyncScript.new()
	lip.name = "LipSync"
	lip.face_mesh_path = NodePath("../FaceMesh")
	lip.audio_player_path = NodePath("Voice")
	var audio := AudioStreamPlayer.new()
	audio.name = "Voice"
	lip.add_child(audio)
	container.add_child(lip)
	get_root().add_child(container)
	face.set_process(false)
	lip.set_process(false)
	return {"root": container, "mesh": mesh, "face": face, "lip": lip}

func _test_mesh(shapes: Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	for shape in shapes:
		mesh.add_blend_shape(shape)
	var vertices := PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.FORWARD])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2])
	var blend_shapes: Array = []
	for shape in shapes:
		var target: Array = []
		target.resize(Mesh.ARRAY_MAX)
		target[Mesh.ARRAY_VERTEX] = vertices
		blend_shapes.append(target)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, blend_shapes)
	return mesh

func _cue_file(name: String, cues: Array, env: Array = []) -> String:
	var path := OS.get_temp_dir().path_join("face_test_%d_%s.json" % [OS.get_process_id(), name])
	var data := {"duration": 1.0, "cues": cues.map(func(c): return {"t": c[0], "shape": c[1], "weight": c[2]})}
	if not env.is_empty():
		data["env"] = env
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "could not write cue fixture: " + path)
		return path
	file.store_string(JSON.stringify(data))
	file.close()
	_fixtures.append(path)
	return path

func _silent_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	var silence := PackedByteArray()
	silence.resize(44100 * 2)
	stream.data = silence
	return stream

func _find_face(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and node.mesh != null and node.find_blend_shape_by_name("eyesBlink") >= 0:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _find_face(child)
		if found != null:
			return found
	return null

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func _weight(mesh: MeshInstance3D, shape: String) -> float:
	return mesh.get_blend_shape_value(mesh.find_blend_shape_by_name(shape))

func _angle(a: Quaternion, b: Quaternion) -> float:
	return rad_to_deg(a.angle_to(b))

func _near(actual: float, expected: float) -> bool:
	return absf(actual - expected) < 0.002

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("  ok   ", message)
	else:
		_failed = true
		push_error("FAIL " + message)
