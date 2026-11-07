extends SceneTree

const Trainer = preload("res://scripts/trainer/mission_trainer.gd")
const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var failures := 0
var probe: Array[String] = []
var shots: Array[String] = []
var active_player: Control

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	if not storage.setup("M1-64-capture") or not storage.prepare_rendering_cache():
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.always_on_top = true
	root.grab_focus()
	var trainer := Trainer.new()
	trainer.results_path = storage.directory.path_join("trainer.json")
	root.add_child(trainer)
	trainer.select_scenario("P-02")
	trainer.open_decision()
	var player = trainer.panels.hint_player
	active_player = player
	player.seen_path = storage.directory.path_join("how-to.cfg")
	if OS.get_cmdline_user_args().has("--still-only"):
		player.close()
		await _capture_still(player)
		trainer.free()
		_finish("still_")
		return
	if OS.get_cmdline_user_args().has("--context-only"):
		player.close()
		trainer.table.reveal_hint()
		for large in [false, true]:
			player.set_settings({"large_text": large})
			_expect(player.level == 1, "same requested table nudge remains level one when text size changes")
			await _capture("hint_1" + ("_150" if large else ""))
		player.close()
		trainer.free()
		await _capture_campaign()
		_finish("context_")
		return
	await _capture("first_time_how_to")
	player.close()
	await _capture("table_hint_entry")
	for level in range(1, 4):
		(trainer.table.find_child("Hint", true, false) as Button).grab_focus()
		trainer.table.reveal_hint()
		if level == 2:
			await _wait_video(player, 5.0)
			player.toggle_pause()
			await _capture("hint_2_caption_pause")
			var position: float = player.video.stream_position
			await create_timer(0.2).timeout
			_expect(player.video.stream_position == position, "actual Pause freezes registered clip")
			player.replay()
			await _wait_video(player, 1.0)
			await _capture("hint_2_replay")
		else:
			await _capture("hint_%d" % level)
		player.close()
	player.show_how_to("mission_table")
	(player.find_child("HowToClip", true, false) as Button).pressed.emit()
	await _wait_video(player, 5.0)
	await _capture("how_to_concept")
	player.close()
	trainer.table._more = true
	trainer.table._render()
	await _capture("table_more")
	for large in [false, true]:
		var suffix := "_150" if large else ""
		player.set_settings({"large_text": large, "captions": true, "reduced_motion": false})
		player.request_hint("missing" + suffix, {"nudge": "Look at the reading.", "clip": "missing", "relationship": "Compare before and after. The clip is unavailable; this text explains the relationship.", "example": "Different example: 9 minus 3 leaves 6."})
		player.close()
		player.request_hint("missing" + suffix, {"nudge": "Look at the reading.", "clip": "missing", "relationship": "Compare before and after. The clip is unavailable; this text explains the relationship.", "example": "Different example: 9 minus 3 leaves 6."})
		await _capture("missing_clip" + suffix)
		player.close()
	await _capture_still(player)
	trainer.settings.large_text = true
	trainer.table.open(trainer.exercise, trainer.exercise.current_gate(), trainer.settings)
	await _capture("table_hint_entry_150")
	for level in range(1, 4):
		player.set_settings({"large_text": true, "captions": true, "reduced_motion": false})
		player.request_hint("table_150", HowToCard.lesson("mission_table"), trainer.table._hint_target())
		if level == 2:
			await _wait_video(player, 5.0)
			player.toggle_pause()
		await _capture("hint_%d_150" % level)
		player.close()
	trainer.free()
	await _capture_campaign()
	_finish()

func _capture_campaign() -> void:
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	if campaign.loading:
		await campaign.wait_loading()
	await process_frame
	var hud := campaign.hud
	active_player = hud.panels.hint_player
	for source in ["what_now", "journal"]:
		if source == "what_now":
			hud.panels.open_panel("what_now")
		else:
			hud.panels.open_journal("now")
		for large in [false, true]:
			hud.panels.set_accessibility({"large_text": large})
			await _capture(("what_now" if source == "what_now" else "journal_hint_entry") + ("_150" if large else ""))
		hud.panels.set_accessibility({"large_text": false})
		var button: Button = hud.find_child("WhatNowHint", true, false) if source == "what_now" else hud.panels.find_child("RevealHint", true, false)
		button.grab_focus()
		button.pressed.emit()
		for large in [false, true]:
			active_player.set_settings({"large_text": large})
			var expected_level := 1 if source == "what_now" else 2
			_expect(active_player.level == expected_level and (active_player._stack.get_child(0) as Label).text.begins_with("Hint %d of 3" % expected_level), "%s large=%s preserves genuine requested level %d" % [source, large, expected_level])
			if expected_level == 1:
				_expect((active_player._body.get_child(0) as Label).text == "Follow the arrow after the battery is full.", "world nudge preserves authored scene H1")
			await _capture(("world_nudge" if source == "what_now" else "journal_shared_hint") + ("_150" if large else ""))
			if expected_level == 1:
				probe.append("World nudge large=%s marker visible=%s target=%s rect=%s" % [large, hud._marker.visible, hud._marker_node.name if hud._marker_node != null else "none", hud._marker.get_global_rect()])
		active_player.close()
		hud.panels.close_panel()
	campaign.free()

func _capture_still(player: Control) -> void:
	player.set_settings({"large_text": true, "captions": true, "reduced_motion": true})
	player.show_how_to("mission_table")
	await _capture("how_to_150")
	(player.find_child("HowToClip", true, false) as Button).pressed.emit()
	var still_deadline := Time.get_ticks_msec() + 10000
	while player._still_pending and Time.get_ticks_msec() < still_deadline:
		await process_frame
	var first_caption: float = player._entry.captions[0].start
	_expect(player.video.paused and player.video.modulate.a == 1.0 and player._has_visible_frame() and player.video.stream_position >= first_caption, "reduced-motion still shows a decoded scientific caption frame, beyond the title card")
	await _capture("reduced_motion_still_150")
	var frozen_position: float = player.video.stream_position
	var pixels = player.video.get_video_texture().get_image().get_data()
	var checksum: int = hash(pixels)
	await create_timer(0.5).timeout
	_expect(player.video.paused and player.video.modulate.a == 1.0 and player.video.stream_position == frozen_position and checksum == hash(player.video.get_video_texture().get_image().get_data()), "real reduced-motion texture and position stay identical for half a second")
	probe.append("Actual registered still: %s; texture=%s; position=%s; first_caption=%s; hash=%s; paused=%s" % [player.video.stream.resource_path, player.video.get_video_texture().get_size(), frozen_position, first_caption, checksum, player.video.paused])
	await _capture("reduced_motion_still_150_held")
	player.set_settings({"captions": false})
	await _capture("reduced_motion_captions_off_150")
	player.close()

func _finish(prefix: String = "") -> void:
	DirAccess.remove_absolute(storage.directory.path_join("how-to.cfg"))
	DirAccess.remove_absolute(storage.directory.path_join("trainer.json"))
	storage.cleanup()
	var file := FileAccess.open("res://../production/qa/evidence/M1-64_%scapture_probe.txt" % prefix, FileAccess.WRITE)
	file.store_string("\n".join(probe) + "\nScreenshots: " + ", ".join(shots) + "\n")
	file.close()
	print("M1-64 CAPTURE RESULT: %s (%d captures, %d failures)" % ["PASS" if failures == 0 else "FAIL", shots.size(), failures])
	quit(0 if failures == 0 else 1)

func _wait_video(player: Control, seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + 12000
	while player.video.stream_position < seconds and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(player.video.stream_position >= seconds, "actual registered video reaches %s seconds" % seconds)

func _capture(id: String) -> void:
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	if is_instance_valid(active_player) and active_player.is_open():
		for button in active_player._frame.find_children("*", "Button", true, false):
			var text_width: float = button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
			_expect(button.size.x >= text_width and button.size.y >= 44 and button.size.y < 80, "%s: %s has readable text and target size %s" % [id, button.name, button.size])
		if active_player.mode == "hint" and active_player.level == 1:
			_expect(active_player._scroll.size.y >= active_player._body.get_combined_minimum_size().y, id + ": full nudge is visible")
		if is_instance_valid(active_player.video) and active_player.video.stream != null:
			var picture: Rect2 = active_player.video.get_global_rect()
			_expect(picture.size.y >= 180 and is_equal_approx(picture.size.x / picture.size.y, 16.0 / 9.0) and active_player._scroll.get_global_rect().encloses(picture), id + ": whole 16:9 picture fits the body")
	var name := "M1-64_" + id + ".png"
	var error := root.get_texture().get_image().save_png("res://../production/qa/evidence/" + name)
	_expect(error == OK, "captured " + name)
	shots.append(name)

func _expect(value: bool, label: String) -> void:
	probe.append(("PASS " if value else "FAIL ") + label)
	if not value:
		failures += 1
		push_error(label)
