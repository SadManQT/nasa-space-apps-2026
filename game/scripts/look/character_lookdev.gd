extends Node3D
class_name CharacterLookdev

const CAST: Array[String] = ["CH_Kai", "CH_Amara", "CH_Mei", "CH_Rafi", "CH_Ferreira"]
const PROP_PATHS: Array[String] = [
	"res://assets/props/PR_MissionTable/PR_MissionTable.glb",
	"res://assets/props/PR_CrewSeat/PR_CrewSeat.glb",
	"res://assets/props/PR_ControlConsole/PR_ControlConsole.glb",
]
const PROP_POSITIONS: Array[Vector3] = [Vector3(-4.3, 0.0, -1.6), Vector3(4.1, 0.0, -1.45), Vector3(0.0, 0.0, -2.25)]
const CHARACTER_POSITIONS: Array[Vector3] = [Vector3(-3.2, 0.0, 0.0), Vector3(-1.6, 0.0, 0.15), Vector3(0.0, 0.0, 0.0), Vector3(1.6, 0.0, 0.15), Vector3(3.2, 0.0, 0.0)]
const EXPRESSIONS: Array[String] = ["neutral", "happy", "worried", "surprised", "serious"]

@onready var _camera: Camera3D = $Camera
@onready var _stage: Node3D = $Stage

var _characters: Array[Node3D] = []
var _kai_face: FaceAtlas
var _expression_elapsed := 0.0
var _expression_index := 0

func _ready() -> void:
	_build_floor()
	_load_props()
	_load_characters()
	ToonMaterials.apply_to_tree(_stage, false, true)
	_camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	for arg in OS.get_cmdline_user_args():   # --closeup=<cast index>[:<metres>]: frame one character (under 1.5 m: the face)
		if arg.begins_with("--closeup="):
			var parts := arg.trim_prefix("--closeup=").split(":")
			var index := clampi(int(parts[0]), 0, CAST.size() - 1)
			var distance := float(parts[1]) if parts.size() > 1 else 2.4
			var target := CHARACTER_POSITIONS[index] + Vector3(0.0, 1.15, 0.0)
			if distance < 1.5 and index < _characters.size():   # the face: aim at this character's own head
				var skeleton := _characters[index].find_child("Skeleton3D", true, false) as Skeleton3D
				var head := skeleton.find_bone("mixamorig_Head") if skeleton else -1
				if head >= 0:
					target = (skeleton.global_transform * skeleton.get_bone_global_pose(head)).origin + Vector3(0.0, 0.08, 0.0)
			_camera.position = target + Vector3(0.25, 0.06, 1.0) * distance
			_camera.look_at(target, Vector3.UP)
	print("LOOKDEV loaded %d v7 characters" % _characters.size())

func _process(delta: float) -> void:
	if _kai_face == null:
		return
	_expression_elapsed += delta
	if _expression_elapsed >= 1.8:
		_expression_elapsed = 0.0
		_expression_index = (_expression_index + 1) % EXPRESSIONS.size()
		_kai_face.set_expression(EXPRESSIONS[_expression_index])

func _build_floor() -> void:
	var ground := $Stage/Ground as MeshInstance3D
	var material := ground.get_active_material(0) as StandardMaterial3D
	if material != null:
		material.albedo_color = Color("#252d3b")
		material.roughness = 0.86

func _load_props() -> void:
	var props := Node3D.new()
	props.name = "Props"
	_stage.add_child(props)
	for i in PROP_PATHS.size():
		var scene := load(PROP_PATHS[i]) as PackedScene
		if scene == null:
			push_warning("LOOKDEV prop missing: " + PROP_PATHS[i])
			continue
		var prop := scene.instantiate() as Node3D
		if prop == null:
			continue
		prop.name = PROP_PATHS[i].get_file().get_basename()
		prop.position = PROP_POSITIONS[i]
		props.add_child(prop)
		ToonMaterials.apply_to_tree(prop, false, true)

func _load_characters() -> void:
	var cast_root := Node3D.new()
	cast_root.name = "Cast"
	_stage.add_child(cast_root)
	for i in CAST.size():
		var path := "res://assets/characters/%s/%s.glb" % [CAST[i], CAST[i]]
		var character := _instantiate_gltf(path)
		if character == null:
			push_warning("LOOKDEV character missing: " + path)
			continue
		character.name = CAST[i]
		character.position = CHARACTER_POSITIONS[i]
		cast_root.add_child(character)
		ToonMaterials.apply_to_tree(character, true, true)
		_play_idle(character)
		_setup_springs(character)
		_characters.append(character)
		if i == 0:
			_setup_face(character)

func _instantiate_gltf(path: String) -> Node3D:
	if not FileAccess.file_exists(path):
		return null
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	var error: Error = document.append_from_file(path, state)
	if error != OK:
		push_error("LOOKDEV GLB import failed (%s): %s" % [error, path])
		return null
	return document.generate_scene(state) as Node3D

func _play_idle(character: Node3D) -> void:
	var players := character.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var player := players[0] as AnimationPlayer
	if player.has_animation("Idle_loop"):
		player.play("Idle_loop")

func _setup_springs(character: Node3D) -> void:
	var skeleton := character.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null:
		return
	var springs := HairSprings.new()
	springs.name = "HairSprings"
	character.add_child(springs)
	springs.build(skeleton)

func _setup_face(character: Node3D) -> void:
	_kai_face = FaceAtlas.new()
	_kai_face.name = "FaceAtlas"
	character.add_child(_kai_face)
	_kai_face.setup(character)
	var voice := AudioStreamPlayer.new()
	voice.name = "Voice"
	character.add_child(voice)
	_kai_face.audio_player_path = _kai_face.get_path_to(voice)
	_kai_face.play_line(_silence_stream(3.0), "res://tools/test_data/kai_test_visemes.json")

func _silence_stream(seconds: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	var data := PackedByteArray()
	data.resize(int(44100.0 * seconds) * 2)
	stream.data = data
	return stream
