extends SceneTree
# Turns a cutscene master into the Ogg Theora file Godot plays (Godot's Movie Maker is the only Theora encoder at
# hand: the Homebrew ffmpeg has none). Shows the master's frames, one per movie frame, while its mix plays.
#   ffmpeg -i <master.mp4> -vf fps=24,scale=1152:648 -q:v 2 <frames>/%05d.jpg
#   Godot --path game --resolution 1152x648 --write-movie <out.ogv> --fixed-fps 24 -s ogv_writer.gd -- <frames> <mix.wav>
var frames: Array[String] = []
var picture: TextureRect
var index := 0
var mix: AudioStreamPlayer

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for file in DirAccess.get_files_at(args[0]):
		if file.ends_with(".jpg"):
			frames.append(args[0].path_join(file))
	frames.sort()
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(black)
	picture = TextureRect.new()
	picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(picture)
	mix = AudioStreamPlayer.new()
	mix.stream = AudioStreamWAV.load_from_file(args[1])
	root.add_child(mix)

func _process(_delta: float) -> bool:
	if index >= frames.size():
		return true
	if index == 0:
		mix.play()   # once the player is in the tree, on the first recorded frame
	picture.texture = ImageTexture.create_from_image(Image.load_from_file(frames[index]))
	index += 1
	return false
