## M4-03: capture the actual cutscene player closing CS-18 on the D13
## dedication, with its window on top. Run via production/qa/evidence/M4-03_capture.sh.
## Shots: OPT02 at 7.5 s (words on the film's black) and 8.5 s (the held black
## after the 8.0 s film), OPT01 at 7.5 s (nothing drawn).
extends SceneTree

const SHOTS := [
	["opt02", "EX-CH08-S12-OPT02", [7.5, 8.5]],
	["opt01", "EX-CH08-S12-OPT01", [7.5]],
]
const EVIDENCE := "res://../production/qa/evidence/M4-03_dedication_%s_%ss.png"
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("M4-03 CAPTURE RESULT: FAIL (a window is required)")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.always_on_top = true
	root.grab_focus()
	var plans := CampaignCutsceneRuntime.new().plans_for_scene("EX-CH08-S12", "campaign_complete")
	if plans.size() != 1 or (plans[0] as Dictionary).get("choice_card", {}).is_empty():
		print("M4-03 CAPTURE RESULT: FAIL (CS-18 has no choice card plan)")
		quit(1)
		return
	for shot in SHOTS:
		var director := CampaignDirector.new()
		director.new_campaign()
		var snapshot := director.snapshot()
		snapshot.story_log.choices["EX-CH08-S12-CHOICE"] = {"option_id": String(shot[1]), "scene_id": "EX-CH08-S12", "scenario_datetime": snapshot.scenario_datetime, "state_revision": snapshot.state_revision}
		if not bool(director.restore_snapshot(snapshot).get("accepted", false)):
			failures += 1
			print("M4-03 save with ", shot[1], " was refused")
			continue
		var player := CampaignCutscenePlayer.new()
		player.snapshot_source = director.snapshot
		root.add_child(player)
		await process_frame
		var finished := {"at": -1}
		player.closed.connect(func(_result: Dictionary) -> void: finished.at = Time.get_ticks_msec())
		var start := Time.get_ticks_msec()
		player.play(plans[0])
		for at in shot[2]:
			while player.is_active() and player.position_s() < float(at) and Time.get_ticks_msec() - start < 20000:
				await process_frame
			if not player.is_active() or absf(player.position_s() - float(at)) > 0.1:
				failures += 1
				print("M4-03 missed capture: ", shot[0], " ", at, " active=", player.is_active(), " position=", player.position_s())
				break
			# The first windowed frames after a shader compile can come back blank: retry a few.
			var image: Image
			for attempt in 4:
				await RenderingServer.frame_post_draw
				image = root.get_texture().get_image()
				if _lit(image, Rect2i(24, 18, 180, 34)):
					break
			var destination := EVIDENCE % [String(shot[0]), String.num(float(at), 1)]
			var error := image.save_png(ProjectSettings.globalize_path(destination))
			var words_lit := _lit(image, Rect2i(240, 600, 800, 100))
			var expect_words := String(shot[0]) == "opt02"
			if error != OK or words_lit != expect_words:
				failures += 1
			print("M4-03 screenshot: ", destination.get_file(), " at ", snappedf(player.position_s(), 0.001), " s; words on screen: '", player.choice_card_text(), "' (lit pixels in the bottom band: ", words_lit, "); error ", error)
		while player.is_active() and Time.get_ticks_msec() - start < 20000:
			await process_frame
		print("M4-03 ", shot[0], " closed at ", snappedf((int(finished.at) - start) / 1000.0, 0.01), " s after play")
		player.free()
		await process_frame
	print("M4-03 CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

## True when the region holds pixels clearly brighter than the film's black.
func _lit(image: Image, region: Rect2i) -> bool:
	if image == null or image.is_empty():
		return false
	for y in range(region.position.y, region.end.y, 2):
		for x in range(region.position.x, region.end.x, 2):
			if image.get_pixel(x, y).get_luminance() > 0.35:
				return true
	return false
