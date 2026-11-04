## Campaign audio playback: the scene's music cue and looping beds, the voice of
## the caption on screen, operation and alert effects, and short captions for
## essential sounds. Presentation only: nothing here reads or writes gameplay
## state, and every missing file leaves its caption as the presentation.
## Mix rules (dialogue first, music ducks under speech) come from
## presentation_media.json audio.mix.
extends Node
class_name CampaignAudioDirector

var runtime: CampaignAudioRuntime
var preparation: LoadPreparation
## Essential-sound captions follow the player's Captions setting.
var captions_enabled := true
## Line currently voiced or waiting to be voiced ("" for none).
var voice_line_id := ""
var voice: AudioStreamPlayer
var sound_caption: Label
var _music: Array[AudioStreamPlayer] = []
var _music_path := ""
var _sting: AudioStreamPlayer
var _channel: AudioStreamPlayer
var _beds := {}
var _oneshots: Array[AudioStreamPlayer] = []
var _cache := {}
var _heard := {}
var _cinematic := false
var _paused := false
var _voice_pending := false
var _voice_plan := {}
var _voice_origin := ""
var _scene_id := ""
var _room_id := ""
var _scene_dirty := false
var _opened_channels := {}
var _duck := 0.0
var _captions: Array = []

## Binds the plan source and the optional shared loader, and applies saved volumes.
func setup(audio_runtime: CampaignAudioRuntime, prepared: LoadPreparation = null) -> void:
	runtime = audio_runtime
	preparation = prepared
	AudioSettings.apply_all()

func _ready() -> void:
	voice = _player("Voice", "Voice")
	_music = [_player("MusicA", "Music"), _player("MusicB", "Music")]
	for player in _music:
		player.set_meta("fade", 0.0)
		player.set_meta("fade_to", 0.0)
	_sting = _player("Sting", "Music")
	_channel = _player("Channel", "SFX")
	for index in 4:
		_oneshots.append(_player("Effect%d" % index, "SFX"))
	voice.finished.connect(_on_voice_finished)
	var layer := CanvasLayer.new()
	layer.layer = 150
	add_child(layer)
	sound_caption = Label.new()
	sound_caption.name = "SoundCaption"
	sound_caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sound_caption.offset_top = -238
	sound_caption.offset_bottom = -204
	sound_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sound_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sound_caption.add_theme_font_size_override("font_size", 16)
	sound_caption.add_theme_color_override("font_color", Color("#A8B4C8"))
	sound_caption.add_theme_color_override("font_outline_color", Color("#05060A"))
	sound_caption.add_theme_constant_override("outline_size", 5)
	layer.add_child(sound_caption)

## The scene changed (or its world was rebuilt): retarget music and beds and
## queue its opening effects. A repeat call for the same scene changes nothing.
func enter_scene(scene_id: String, room_id: String) -> void:
	if scene_id == _scene_id and room_id == _room_id:
		return
	_scene_id = scene_id
	_room_id = room_id
	_opened_channels.clear()
	_scene_dirty = true

## The caption on screen changed. Voices it once (unless it was already heard,
## e.g. in the cutscene just watched); the caption itself is the HUD's.
func present_line(line: Dictionary, acquired_flags: Array = []) -> void:
	var line_id := String(line.get("id", ""))
	if line_id == voice_line_id:
		return
	_stop_voice()
	voice_line_id = line_id
	if line_id.is_empty() or _heard.has(line_id) or runtime == null:
		return
	_voice_plan = runtime.voice_plan(line_id, acquired_flags)
	_voice_origin = String(line.get("origin", line.get("delivery", "")))
	_voice_pending = String(_voice_plan.get("mode", "")) == "voice"

## Lines the player has already heard this session are shown without voice.
func mark_heard(line_ids: Array) -> void:
	for id in line_ids:
		_heard[String(id)] = true
	if _heard.has(voice_line_id):
		_stop_voice()

## A cutscene is on screen: hold every campaign sound; its film carries its own mix.
func set_cinematic(value: bool) -> void:
	_cinematic = value
	_hold_streams()

## A reading panel or the loading card is open: hold the voice, keep the room alive.
func set_paused(value: bool) -> void:
	_paused = value
	_hold_streams()

## One-shot for a physical operation's result (soft error when rejected).
func play_operation(target_id: String, label: String, accepted: bool) -> void:
	if runtime != null:
		_play_oneshot(runtime.operation_sfx(target_id, label, accepted))

## The campaign is complete: the credits loop replaces the scene cue.
func play_credits() -> void:
	if runtime != null:
		_set_music(runtime.credits_music_path())

## Loads a scene's music and beds in the background so entering it starts at once.
func prefetch(scene_id: String, room_id: String) -> void:
	if runtime == null:
		return
	for path in runtime.scene_media_paths(scene_id, room_id):
		await _stream(path)

## Current music duck in dB (0 when no one speaks).
func music_duck_db() -> float:
	return _mix("music_duck_db", 8.0) * _duck

## The music player carrying the current cue, or null in silence.
func music_player() -> AudioStreamPlayer:
	for player in _music:
		if float(player.get_meta("fade_to")) > 0.0 and player.playing:
			return player
	return null

## Ids of the looping beds playing now.
func playing_beds() -> Array:
	return _beds.keys().filter(func(id) -> bool: return _beds[id].playing)

func _process(delta: float) -> void:
	if runtime == null:
		return
	if not _cinematic:
		if _scene_dirty:
			_scene_dirty = false
			_apply_scene()
		if _voice_pending and not _paused:
			_voice_pending = false
			_start_voice()
	var speaking := voice.playing and not voice.stream_paused
	var rate := delta / maxf(_mix("duck_attack_s" if speaking else "duck_release_s", 0.15), 0.001)
	_duck = move_toward(_duck, 1.0 if speaking else 0.0, rate)
	var fade_rate := delta / maxf(_mix("music_fade_s", 1.5), 0.001)
	for player in _music:
		var fade := move_toward(float(player.get_meta("fade")), float(player.get_meta("fade_to")), fade_rate)
		player.set_meta("fade", fade)
		player.volume_db = _mix("music_db", -8.0) + linear_to_db(maxf(fade, 0.0001)) - music_duck_db()
		if fade <= 0.0 and player.playing:
			player.stop()
	var bed_db := _mix("beds_db", -6.0) - _mix("effects_duck_db", 4.0) * _duck
	for player in _beds.values():
		player.volume_db = bed_db
	_update_captions()

func _apply_scene() -> void:
	var music := runtime.music_for_scene(_scene_id)
	_set_music(String(music.get("runtime_path", "")))
	var wanted := runtime.beds_for_scene(_scene_id, _room_id)
	var wanted_ids := wanted.map(func(plan) -> String: return plan.id)
	for id in _beds.keys():
		if not wanted_ids.has(id):
			_beds[id].queue_free()
			_beds.erase(id)
	for plan in wanted:
		if not _beds.has(plan.id) and bool(plan.media_present):
			var player := _player(plan.id, plan.bus)
			player.volume_db = _mix("beds_db", -6.0)
			_beds[plan.id] = player
			_start(player, plan.runtime_path, plan.caption)
	if not String(music.get("sting_path", "")).is_empty():
		_start(_sting, music.sting_path)
	for plan in runtime.scene_sfx(_scene_id):
		_play_oneshot(plan)
	# ponytail: cache holds the current scene's files only; prefetch refills it for the next.
	var keep := runtime.scene_media_paths(_scene_id, _room_id)
	for path in _cache.keys():
		if not keep.has(path):
			_cache.erase(path)

func _set_music(path: String) -> void:
	if path == _music_path:
		return
	_music_path = path
	for player in _music:
		player.set_meta("fade_to", 0.0)
	if path.is_empty():
		return
	var next := _music[0] if float(_music[0].get_meta("fade")) <= float(_music[1].get_meta("fade")) else _music[1]
	next.stop()
	next.set_meta("fade", 0.0)
	next.set_meta("fade_to", 1.0)
	_start(next, path)

func _start_voice() -> void:
	var line_id := voice_line_id
	var stream := await _stream(String(_voice_plan.get("runtime_path", "")))
	if stream == null or line_id != voice_line_id:
		return
	var channel := runtime.line_sfx(_voice_origin)
	if bool(channel.get("media_present", false)) and (bool(channel.loop) or not _opened_channels.has(_voice_origin)):
		_opened_channels[_voice_origin] = true
		_start(_channel, channel.runtime_path, channel.caption)
	voice.stream = stream
	voice.play()
	_hold_streams()

func _stop_voice() -> void:
	_voice_pending = false
	voice.stop()
	if _channel.stream != null and _channel.stream.get("loop"):
		_channel.stop()

func _on_voice_finished() -> void:
	_heard[voice_line_id] = true
	if _channel.stream != null and _channel.stream.get("loop"):
		_channel.stop()

func _play_oneshot(plan: Dictionary) -> void:
	if not bool(plan.get("media_present", false)):
		_caption(String(plan.get("caption", "")))
		return
	var player := _oneshots[0]
	for candidate in _oneshots:
		if not candidate.playing:
			player = candidate
			break
	player.bus = String(plan.bus)
	player.volume_db = _mix("ui_db" if plan.bus == "UI" else "sfx_db", 0.0)
	_start(player, plan.runtime_path, plan.caption)

func _start(player: AudioStreamPlayer, path: String, caption: String = "") -> void:
	var stream := await _stream(path)
	if stream == null or not is_instance_valid(player):
		return
	if player in _music and path != _music_path:
		return
	player.stream = stream
	player.play()
	_hold_streams()
	_caption(caption)

func _hold_streams() -> void:
	voice.stream_paused = _cinematic or _paused
	_channel.stream_paused = _cinematic or _paused
	for player in _music + [_sting] + _beds.values():
		player.stream_paused = _cinematic

## Threaded load shared with LoadPreparation's cache; never blocks a frame on decode.
func _stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if _cache.has(path):
		return _cache[path]
	if preparation != null and preparation.resources.has(path):
		return preparation.resources[path] as AudioStream
	var stream: AudioStream = null
	if ResourceLoader.has_cached(path):
		stream = load(path) as AudioStream
	elif ResourceLoader.load_threaded_request(path) == OK:
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		stream = ResourceLoader.load_threaded_get(path) as AudioStream
	if stream == null and ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	if stream != null:
		_cache[path] = stream
	return stream

func _caption(text: String) -> void:
	if text.is_empty():
		return
	_captions = _captions.filter(func(item) -> bool: return item.text != text)
	_captions.append({"text": text, "until": Time.get_ticks_msec() + int(_mix("sound_caption_s", 3.0) * 1000.0)})

func _update_captions() -> void:
	if _captions.is_empty():
		sound_caption.visible = false
		return
	var now := Time.get_ticks_msec()
	_captions = _captions.filter(func(item) -> bool: return item.until > now)
	sound_caption.visible = captions_enabled and not _cinematic and not _paused and not _captions.is_empty()
	sound_caption.text = "   ".join(_captions.map(func(item) -> String: return item.text))

func _mix(key: String, fallback: float) -> float:
	return runtime.mix(key, fallback) if runtime != null else fallback

func _player(node_name: String, bus: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = bus
	add_child(player)
	return player
