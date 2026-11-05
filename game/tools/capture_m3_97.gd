## M3-97: capture the actual campaign cutscene player, with its window on top.
## Run via production/qa/evidence/M3-97_capture.sh after encoding the masters.
extends SceneTree

const FILMS := [
	["CS-15", "CS-15_Hello_Aurora", [[2.2, "rao_channel"], [6.0, "pause"], [8.5, "noor_live"], [19.5, "noor_reply"], [29.0, "return"]]],
	["CS-17", "CS-17_What_We_Grew", [[15.5, "tara_lineage"], [27.5, "five_named_mugs"]]],
	["CS-18", "CS-18_The_Closed_Drawer", [[2.0, "hold"], [3.84, "blink"], [7.5, "black"]]],
]
var player: CampaignCutscenePlayer
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("M3-97 CAPTURE RESULT: FAIL (a window is required)")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.always_on_top = true
	root.grab_focus()
	player = CampaignCutscenePlayer.new()
	root.add_child(player)
	await process_frame
	for film in FILMS:
		var path := "res://assets/cutscenes/%s.ogv" % String(film[1])
		if not ResourceLoader.exists(path):
			failures += 1
			print("M3-97 missing film: ", path)
			continue
		player.play({"mode": "video", "runtime_path": path, "cutscene_id": film[0], "title": film[0]})
		var deadline := Time.get_ticks_msec() + 75000
		for point in film[2]:
			while player.is_active() and player.position_s() < float(point[0]) and Time.get_ticks_msec() < deadline:
				await process_frame
			if not player.is_active() or absf(player.position_s() - float(point[0])) > 0.3:
				failures += 1
				print("M3-97 missed capture: ", film[0], " ", point)
				break
			await RenderingServer.frame_post_draw
			var destination := "res://../production/qa/evidence/M3-97_%s_ingame_%s.png" % [String(film[0]).replace("-", ""), String(point[1])]
			var error := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(destination))
			if error != OK:
				failures += 1
			print("M3-97 screenshot: ", destination, " at ", player.position_s(), " error ", error)
		player.skip()
		await process_frame
	player.free()
	print("M3-97 CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
