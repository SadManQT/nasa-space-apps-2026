## Windowed, isolated M1-52 evidence: the CS-01 cold open with the M1-52 field beat, playing inside the campaign.
## Run by production/qa/evidence/M1-52_capture.sh after the .ogv is encoded:
##   Godot --path game --windowed --resolution 1280x720 -s ../production/qa/evidence/M1-52_capture.gd
## Screenshots the film at three beats, lets it run to its end, then checks that play resumes with
## the first EX-CH01-S01 line voiced in-engine (the film no longer speaks it).
extends SceneTree

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const BEATS := {"field_wind": 3.0, "exterior_silent": 7.2, "slate_fans": 14.0, "title_gold_band": 18.5}   # seconds into the film
var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var closed: Array = []
var failures := 0

func _init() -> void:
	if not storage.setup("M1-52-capture"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.always_on_top = true
	root.grab_focus()
	CampaignCutscenePlayer.autoplay = true
	campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	campaign.cutscene_closed.connect(func(result: Dictionary) -> void: closed.append(result))
	for _i in range(5):
		await process_frame
	_check(campaign.is_cutscene_active() and campaign.cutscene_player.plan.get("cutscene_id", "") == "CS-01", "a new expedition opens with CS-01")
	var player := campaign.cutscene_player
	_check(String(player.plan.get("mode", "")) == "video" and player.video.is_playing(), "CS-01 plays as video from the .ogv")
	var length := player.video.get_stream_length()
	print("M1-52 CS-01 stream length: %.2f s" % length)
	if length > 0.0:
		_check(length >= 18.0 and length <= 21.0, "the cold open with the field beat runs 18-21 s (got %.2f s)" % length)
	var pending := BEATS.keys()
	var deadline := Time.get_ticks_msec() + 40000
	while not pending.is_empty() and campaign.is_cutscene_active() and Time.get_ticks_msec() < deadline:
		await process_frame
		var at := player.position_s()
		for label in pending.duplicate():
			if at >= float(BEATS[label]):
				pending.erase(label)
				await _capture("film_" + label)
	_check(pending.is_empty(), "every beat was captured (missing: %s)" % [pending])
	while campaign.is_cutscene_active() and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(not closed.is_empty() and not bool(closed[-1].get("skipped", true)) and String(closed[-1].get("mode", "")) == "video", "the film ran to its end on its own")
	_check(campaign.cutscenes.heard_line_ids("CS-01", INF).is_empty(), "the film speaks none of the EX-CH01-S01 lines (no caption cues)")
	for _i in range(20):
		await process_frame
	var lines := campaign.current_dialogue()
	_check(not lines.is_empty() and campaign.audio.voice_line_id == String(lines[0].id) and campaign.audio.voice.playing, "after the film the first scene line is voiced in play")
	_check("SFX_FAN_NORMAL" in campaign.audio.playing_beds(), "the commons fan bed carries on from the film's fans")
	await _capture("after_film_first_line")
	campaign.free()
	storage.cleanup()
	print("CS-01 COLD OPEN CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
	print("%s %s" % ["PASS" if ok else "FAIL", what])

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-52_%s.png" % label)
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		failures += 1
	print("M1-52 evidence: ", path, " (", error, ")")
