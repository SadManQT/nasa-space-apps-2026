# Godot --headless --path game --script res://tools/test_campaign_media.gd
## M1-10 / M1-11: cutscenes play at their scene beats in the real campaign, skip
## completes nothing, a missing OGV falls back to text, voice plays with its
## caption, music ducks under speech, loops loop, volumes persist.
extends SceneTree

const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const ContentScript = preload("res://scripts/content/content_loader.gd")
const VOICE_FIXTURE := "res://tools/test_data/audio/voice_fixture.ogg"
const MUSIC_FIXTURE := "res://tools/test_data/audio/music_fixture.ogg"

var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0
var campaign: Chapter1Campaign
var closed: Array = []

func _init() -> void:
	if not storage.setup("campaign_media"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var metadata := CampaignAudioRuntime.read_metadata()
	_test_manifest(metadata)
	_test_loops(metadata)
	_test_settings()
	await _test_director_fixtures()
	await _test_freed_owner_during_stream()
	await _test_campaign_cutscenes()
	await _test_missing_film_fallback()
	storage.cleanup()
	print("CAMPAIGN MEDIA RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)


func _test_manifest(metadata: Dictionary) -> void:
	var audio: Dictionary = metadata.get("audio", {})
	_check(bool(audio.get("voice_runtime_files_present", false)) and bool(audio.get("music_runtime_files_present", false)) and bool(audio.get("sfx_runtime_files_present", false)), "manifest reports voice, music and effects as installed")
	var content := ContentScript.load_full()
	var voiced := 0
	var missing: Array = []
	for line in content.get("dialogue", []):
		var file := String(line.get("voice_file", ""))
		if file.is_empty():
			continue
		voiced += 1
		if not ResourceLoader.exists("res://" + file.trim_prefix("game/")):
			missing.append(line.id)
	_check(voiced == int(audio.get("voice_files_present", -1)) and missing.is_empty(), "every catalog voice file the manifest counts (%d) opens; missing %s" % [voiced, missing])
	_check(audio.get("music_runtime_files", []).size() == 16 and audio.get("sfx_runtime_files", []).size() == 38, "16 music files and 38 effects are listed (M3-99 added the lamp tick and the Dhaka rooftop, M1-52 the Earth field)")
	var runtime := CampaignAudioRuntime.new(content, metadata)
	_check(runtime.music_for_scene("EX-CH01-S01").get("cue_id", "") == "CUE-01", "CUE-01 opens the campaign")
	_check(runtime.music_for_scene("EX-CH08-S05").get("cue_id", "") == "CUE-03", "a scene named on its own (CUE-03 at EX-CH08-S05) beats a range")
	_check(runtime.music_for_scene("EX-CH07-S08").get("runtime_path", "").ends_with("_high.ogg"), "storm peak uses the high CUE-09 stem")
	_check(runtime.music_for_scene("EX-CH04-S06").get("sting_path", "").ends_with("_Sting.ogg"), "vault discovery gets the CUE-06 sting")
	_check(runtime.credits_music_path().ends_with("_Credits.ogg"), "credits loop is installed")
	for room in ["LOC-06", "LOC-09", "LOC-10", "LOC-12"]:
		var ids: Array = runtime.beds_for_scene("", room).map(func(plan) -> String: return plan.id)
		_check(ids == ["SFX_SUIT_BREATH"], room + " outside carries only suit sound (vacuum rule)")
	_check(runtime.operation_sfx("open_shutter", "Open the safe viewing shutter", true).id == "SFX_SHUTTER_OPEN", "operations map to their effect")
	_check(runtime.operation_sfx("charter_card", "Acknowledge charter", false).id == "SFX_UI_SOFT_ERROR", "a refused operation gets the gentle error, never a buzzer")
	for plan in runtime.beds_for_scene("EX-CH01-S01", "LOC-01") + runtime.scene_sfx("EX-CH02-S12"):
		_check(not String(plan.caption).is_empty(), plan.id + " has a caption for players who cannot hear it")

func _test_loops(metadata: Dictionary) -> void:
	var looping := 0
	for row in metadata.audio.sfx:
		var stream := load(String(row.runtime_path)) as AudioStream
		_check(stream != null and bool(stream.get("loop")) == bool(row.loop), "%s imports with loop=%s" % [row.id, row.loop])
		looping += 1 if bool(row.loop) else 0
	_check(looping == 10, "ten looping effects (fans, pumps, water, suit, recorder, rover, Dhaka rooftop)")
	for cue in metadata.audio.music_cues:
		var stream := load(String(cue.runtime_path)) as AudioStream
		_check(stream != null and bool(stream.get("loop")) == bool(cue.loop), "%s imports with loop=%s" % [cue.id, cue.loop])

func _test_settings() -> void:
	AudioSettings.path = storage.directory.path_join("audio_settings.cfg")
	AudioSettings.forget_cache()
	for bus in AudioSettings.BUSES:
		_check(AudioServer.get_bus_index(bus) >= 0, "bus layout has " + bus)
	AudioSettings.set_volume("Music", 0.5)
	AudioSettings.forget_cache()
	_check(is_equal_approx(AudioSettings.volume("Music"), 0.5), "music volume persists per machine")
	AudioSettings.apply_all()
	_check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) - linear_to_db(0.5)) < 0.01, "music volume is applied to its bus")
	AudioSettings.set_volume("Music", 1.0)
	var panels := (load("res://scenes/ui/campaign_panels.tscn") as PackedScene).instantiate() as CampaignPanels
	root.add_child(panels)
	panels.open_panel("settings_accessibility")
	for bus in AudioSettings.BUSES:
		_check(panels.find_child("volume_" + bus, true, false) is HSlider, "settings offer a %s slider" % bus)
	panels.free()
	DirAccess.remove_absolute(AudioSettings.path)

## Two dummy OGGs: voice plays with its line, the looping music ducks under it and returns.
func _test_director_fixtures() -> void:
	var content := ContentScript.load_full()
	var line := ContentScript.dialogue_by_id(content, "EX-CH01-S01-L01")
	for raw in content.dialogue:
		if raw.id == line.id:
			raw.voice_file = VOICE_FIXTURE
	var metadata := CampaignAudioRuntime.read_metadata()
	metadata.audio.music_by_scene = {"EX-CH01-S01": "CUE-TEST"}
	metadata.audio.music_cues = [{"id": "CUE-TEST", "runtime_path": MUSIC_FIXTURE, "loop": true}]
	var director := CampaignAudioDirector.new()
	director.setup(CampaignAudioRuntime.new(content, metadata))
	root.add_child(director)
	director.enter_scene("EX-CH01-S01", "LOC-01")
	await _frames(20)
	var music := director.music_player()
	_check(music != null and music.stream.resource_path == MUSIC_FIXTURE, "scene music starts from the manifest")
	await _seconds(1.6)
	var base_db := director.runtime.mix("music_db", -8.0)
	_check(music != null and music.playing and absf(music.volume_db - base_db) < 0.5, "looping music keeps playing past its 1 s end at its base level")
	director.present_line(line)
	var ready := await _wait_for_voice_ready(director, line.id, 0.5)
	_check(ready, "voice reports bounded readiness for the line whose caption is shown")
	_check(director.voice.playing and director.voice.stream.resource_path == VOICE_FIXTURE and director.voice_line_id == line.id, "voice plays for the line whose caption is shown")
	await _seconds(0.3)
	var duck := director.runtime.mix("music_duck_db", 0.0)
	_check(duck >= 6.0 and duck <= 9.0 and absf(music.volume_db - (base_db - duck)) < 0.5, "music ducks %.1f dB under speech (got %.1f dB)" % [duck, music.volume_db - base_db])
	director.present_line(line)
	await _seconds(0.6)
	_check(not director.voice.playing and director.voice_line_id == line.id, "re-presenting the same caption never replays its voice")
	await _seconds(0.9)
	_check(absf(music.volume_db - base_db) < 0.5, "music returns to its level after the line")
	director.present_line({})
	director.present_line(line)
	await _frames(3)
	_check(not director.voice.playing, "a line already heard is shown without voice")
	director.queue_free()
	await _frames(2)

func _test_freed_owner_during_stream() -> void:
	var content := ContentScript.load_full()
	var metadata := CampaignAudioRuntime.read_metadata()
	var director := CampaignAudioDirector.new()
	director.setup(CampaignAudioRuntime.new(content, metadata))
	root.add_child(director)
	director.enter_scene("EX-CH01-S02", "LOC-02")
	var line := ContentScript.dialogue_by_id(content, "EX-CH01-S02-L01")
	director.present_line(line)
	await process_frame
	director.free()
	await _frames(3)
	_check(not is_instance_valid(director), "freeing CampaignAudioDirector mid-stream completes without resuming a freed coroutine")


func _test_campaign_cutscenes() -> void:
	CampaignCutscenePlayer.autoplay = true
	campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	campaign.cutscene_closed.connect(func(result: Dictionary) -> void: closed.append(result))
	await _frames(3)
	_check(campaign.is_cutscene_active() and campaign.cutscene_player.plan.get("cutscene_id", "") == "CS-01", "a new expedition opens with CS-01 at EX-CH01-S01")
	_check(String(campaign.cutscene_player.plan.get("mode", "")) == "video" and campaign.cutscene_player.video.is_playing(), "CS-01 plays as full-screen video")
	_check(campaign._player.process_mode == Node.PROCESS_MODE_DISABLED, "the expedition holds still under the film")
	_check(not campaign.audio.voice.playing, "no voice plays under the film")
	var before := _gameplay_state()
	await _press(KEY_E)
	await _press(KEY_SPACE)
	_check(campaign.cutscene_player.video.paused, "Space pauses the film")
	await _press(KEY_SPACE)
	_check(not campaign.cutscene_player.video.paused, "Space resumes it")
	campaign.cutscene_player.skip()
	await _frames(2)
	_check(not closed.is_empty() and bool(closed[-1].skipped) and not bool(closed[-1].completes_predicate) and not bool(closed[-1].completes_scene), "skip reports presentation only")
	_check(_gameplay_state() == before, "watching and skipping (and keys pressed under the film) change no gameplay state")
	_check(not bool(campaign.route.gate_status().get("ready", true)), "the scene gate still waits for its physical operations")
	_check(not campaign.is_cutscene_active() and campaign._player.process_mode == Node.PROCESS_MODE_INHERIT, "play resumes after the skip")
	await _seconds(0.5)
	var lines := campaign.current_dialogue()
	_check(campaign.hud._caption_line.text == String(lines[0].text) and campaign.audio.voice_line_id == String(lines[0].id) and campaign.audio.voice.playing, "after a skip at 0 s the first caption is voiced with its own line")
	_check(campaign.audio.music_player() != null and "SFX_FAN_NORMAL" in campaign.audio.playing_beds(), "commons music and fan bed start after the film")
	var target := campaign.physical_target("commission_route")
	campaign._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
	campaign._player.velocity = Vector3.ZERO
	await physics_frame
	await physics_frame
	var result := campaign.perform_target("commission_route")
	_check(bool(result.get("accepted", false)), "operations work after the film")
	for scene in [["EX-CH01-S09", "CS-02"], ["EX-CH01-S12", "CS-03"]]:
		campaign.route.start_at(scene[0])
		campaign._sync_route_projection()
		campaign._refresh_world()
		campaign.hud.refresh_scene()
		await _frames(3)
		_check(campaign.is_cutscene_active() and campaign.cutscene_player.plan.get("cutscene_id", "") == scene[1], "%s plays %s at the scene start" % [scene[0], scene[1]])
		if scene[1] == "CS-03":
			campaign.cutscene_player._close(false, true)
		else:
			var esc := InputEventKey.new()
			esc.physical_keycode = KEY_ESCAPE
			esc.pressed = true
			Input.parse_input_event(esc)
			await _seconds(campaign.cutscene_player.skip_hold_s * 0.5)
			_check(campaign.is_cutscene_active(), "a short Esc press does not skip")
			await _seconds(campaign.cutscene_player.skip_hold_s * 0.7)
			_check(not campaign.is_cutscene_active() and bool(closed[-1].skipped), "holding Esc skips " + scene[1])
			esc = esc.duplicate()
			esc.pressed = false
			Input.parse_input_event(esc)
		await _frames(2)
		campaign._refresh_world()
		await _frames(2)
		_check(not campaign.is_cutscene_active(), scene[1] + " plays once; rebuilding the room does not replay it")
	await _frames(5)
	_check(campaign.audio.voice_line_id == "EX-CH01-S12-L01" and not campaign.audio.voice.playing, "lines the film already spoke are captioned without a second voice")
	_check(campaign.cutscenes.heard_line_ids("CS-03", 25.0) == ["EX-CH01-S12-L01", "EX-CH01-S12-L02"], "caption cues mark what a partly watched film has said")
	_check(campaign.cutscenes.plans_for_scene("EX-CH08-S12", "campaign_complete").map(func(p) -> String: return p.cutscene_id) == ["CS-18"], "CS-18 waits for campaign completion")
	campaign.free()
	await _frames(2)

func _test_missing_film_fallback() -> void:
	campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await _frames(3)
	if campaign.is_cutscene_active():
		campaign.cutscene_player.skip()
	var metadata := CampaignAudioRuntime.read_metadata()
	for item in metadata.available_cutscenes:
		if item.id == "CS-02":
			item.runtime_path = "res://assets/cutscenes/CS-02_missing_for_test.ogv"
	campaign.cutscenes = CampaignCutsceneRuntime.new(campaign.content, metadata)
	campaign.route.start_at("EX-CH01-S09")
	campaign._sync_route_projection()
	campaign._refresh_world()
	await _frames(3)
	var player := campaign.cutscene_player
	_check(campaign.is_cutscene_active() and player.plan.get("mode", "") == "text_fallback", "a missing OGV opens the text fallback")
	_check(player._fallback.visible and not player._frame.visible and player._fallback_text.text.contains(String(campaign.current_dialogue()[0].text)), "the fallback shows the scene's exact lines")
	var before := _gameplay_state()
	await _press(KEY_SPACE)
	_check(not campaign.is_cutscene_active() and _gameplay_state() == before, "dismissing the text card resumes play and changes nothing")
	campaign.free()
	CampaignCutscenePlayer.autoplay = false
	await _frames(2)

func _press(key: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = key
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames(2)

## The campaign snapshot without its save-slot stamp: the slot metadata holds the
## wall-clock save time (to the second) and the rounded play time, which tick on
## their own and are not gameplay state.
func _gameplay_state() -> String:
	var snapshot: Dictionary = campaign._save_snapshot()
	(snapshot.get("presentation_resume", {}) as Dictionary).erase(SaveSlots.SLOT_META_KEY)
	return JSON.stringify(snapshot)

func _frames(count: int) -> void:
	for i in count:
		await process_frame

func _seconds(value: float) -> void:
	var until := Time.get_ticks_msec() + int(value * 1000.0)
	while Time.get_ticks_msec() < until:
		await process_frame

func _wait_for_voice_ready(director: CampaignAudioDirector, line_id: String, timeout_s: float) -> bool:
	var until := Time.get_ticks_msec() + int(timeout_s * 1000.0)
	while Time.get_ticks_msec() < until:
		if director.voice_readiness == "ready" and director.voice_line_id == line_id:
			return true
		await process_frame
	return director.voice_readiness == "ready" and director.voice_line_id == line_id

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
