# Headless test for LipSync: coarticulation timing, closures, loudness, release and error handling.
#   Godot --headless --path game --script res://tools/test_lip_sync.gd
extends SceneTree

const LipSyncScript: Script = preload("res://scripts/lip_sync.gd")
const CUE_PATH: String = "res://tools/test_data/kai_test_visemes.json"

var _failed := false
var _fixture_paths: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var rig := _make_rig()
	var lip = rig[0]
	var face: MeshInstance3D = rig[1]

	# a long vowel holds at full weight until the next cue, then releases into it
	lip.play_line(_silent_stream(), _cues_file("long", 1.0, [[0.0, "viseme_sil", 0.0], [0.1, "viseme_aa", 1.0], [0.6, "viseme_PP", 1.0], [0.7, "viseme_sil", 0.0]]))
	for t in [0.2, 0.35, 0.5]:
		_check(_near(lip.weights_at(t)["viseme_aa"], 1.0), "long vowel holds at %.2f s" % t)
	# closure wins: while the lips seal, opening shapes are suppressed
	var seal: Dictionary = lip.weights_at(0.6)
	_check(seal["viseme_PP"] > 0.99, "PP reaches full weight at its cue")
	_check(seal["viseme_aa"] <= 1.0 - seal["viseme_PP"] + 0.001, "PP suppresses the open vowel")

	# coarticulation: the next shape starts before its cue and the summed opening never exceeds 1
	lip.play_line(_silent_stream(), _cues_file("blend", 1.0, [[0.0, "viseme_E", 1.0], [0.3, "viseme_O", 1.0]]))
	var near_boundary: Dictionary = lip.weights_at(0.29)
	_check(near_boundary["viseme_O"] > 0.0, "next shape anticipates its cue")
	_check(near_boundary["viseme_E"] > 0.0, "previous shape still releasing")
	_check(near_boundary["viseme_E"] + near_boundary["viseme_O"] <= 1.0001, "opening total capped at 1")

	# a very short PP cue still seals for the minimum hold
	lip.play_line(_silent_stream(), _cues_file("short_pp", 1.0, [[0.0, "viseme_aa", 1.0], [0.3, "viseme_PP", 1.0], [0.31, "viseme_aa", 1.0]]))
	var sealed := 0
	for i in 200:
		if lip.weights_at(0.25 + i * 0.001)["viseme_PP"] > 0.99:
			sealed += 1
	_check(sealed >= 45, "short PP held sealed for at least 45 ms (got %d ms)" % sealed)

	# loudness: a silent envelope opens the mouth to 55 percent, a loud one fully
	lip.play_line(_silent_stream(), _cues_file("env", 1.0, [[0.0, "viseme_aa", 1.0]], [0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0]))
	_check(_near(lip.weights_at(0.03)["viseme_aa"], 0.55), "quiet audio scales the opening down")
	_check(_near(lip.weights_at(0.08)["viseme_aa"], 1.0), "loud audio opens fully")

	# repeated playback of the same line gives identical weights
	lip.play_line(_silent_stream(), CUE_PATH)
	var first: Dictionary = lip.weights_at(0.5)
	lip.play_line(_silent_stream(), CUE_PATH)
	_check(first == lip.weights_at(0.5), "repeat playback is deterministic")
	_check(lip.weights_at(99.0).values().all(func(v): return v == 0.0), "after the line everything is at rest")

	# stop(immediate) clears the face at once
	var e_index: int = face.find_blend_shape_by_name("viseme_E")
	face.set_blend_shape_value(e_index, 1.0)
	lip.stop(true)
	_check(_near(face.get_blend_shape_value(e_index), 0.0), "stop(true) clears the face")

	# a missing cue file keeps the face at rest without crashing
	lip.play_line(_silent_stream(), "res://tools/test_data/does_not_exist.json")
	_check(lip.weights_at(0.1).values().all(func(v): return v == 0.0), "missing cue file leaves the face at rest")
	lip.stop(true)

	rig[2].free()
	for path in _fixture_paths:
		DirAccess.remove_absolute(path)
	# Let the dummy audio driver's next mix release stopped playback objects.
	await create_timer(0.1).timeout
	if _failed:
		quit(1)
		return
	print("PASS LipSync coarticulation, closures, loudness, release and errors")
	quit(0)

func _make_rig() -> Array:
	var container := Node.new()
	get_root().add_child(container)
	var lip = LipSyncScript.new()
	container.add_child(lip)
	var face := MeshInstance3D.new()
	face.name = "Face"
	face.mesh = _test_mesh()
	lip.add_child(face)
	var audio := AudioStreamPlayer.new()
	audio.name = "Audio"
	lip.add_child(audio)
	lip.face_mesh_path = NodePath("Face")
	lip.audio_player_path = NodePath("Audio")
	return [lip, face, container]

func _cues_file(name: String, duration: float, cues: Array, env: Array = []) -> String:
	var data := {"duration": duration, "cues": cues.map(func(c): return {"t": c[0], "shape": c[1], "weight": c[2]})}
	if not env.is_empty():
		data["env"] = env
	var path := OS.get_temp_dir().path_join("lip_test_%d_%s.json" % [OS.get_process_id(), name])
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "could not write cue fixture: " + path)
		return path
	_fixture_paths.append(path)
	file.store_string(JSON.stringify(data))
	file.close()
	return path

func _test_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	for shape in LipSyncScript.VISEME_NAMES:
		mesh.add_blend_shape(shape)
	var vertices := PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.FORWARD])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2])
	var blend_shapes: Array = []
	for _shape in LipSyncScript.VISEME_NAMES:
		var target: Array = []
		target.resize(Mesh.ARRAY_MAX)
		target[Mesh.ARRAY_VERTEX] = vertices
		blend_shapes.append(target)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, blend_shapes)
	return mesh

func _silent_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	var silence := PackedByteArray()
	silence.resize(44100 * 2)
	stream.data = silence
	return stream

func _near(actual: Variant, expected: float) -> bool:
	return absf(float(actual) - expected) < 0.01

func _check(condition: bool, message: String) -> void:
	if condition:
		print("  ok   ", message)
	else:
		_failed = true
		push_error("FAIL " + message)
